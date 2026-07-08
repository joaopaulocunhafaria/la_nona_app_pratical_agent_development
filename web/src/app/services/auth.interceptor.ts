import { HttpErrorResponse, HttpHandler, HttpInterceptor, HttpRequest } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Router } from '@angular/router';
import { Observable, catchError, throwError } from 'rxjs';
import { environment } from '../../environments/environment';
import { LocalStorageService } from './local-storage.service';
import { NotificacoesService } from './notificacoes.service';

const ROTAS_SEM_AUTH = ['/auth/login', '/auth/register', '/auth/google', '/auth/refresh'];

@Injectable()
export class AuthInterceptor implements HttpInterceptor {
	constructor(
		private readonly localStorageService: LocalStorageService,
		private readonly notificacoesService: NotificacoesService,
		private readonly router: Router,
	) {}

	intercept(request: HttpRequest<unknown>, next: HttpHandler): Observable<any> {
		// APIs externas (ex.: ViaCEP) devem passar intactas: injetar Authorization/X-Client-Platform
		// vazaria o token para terceiros e transformaria o GET simples numa requisicao CORS com
		// preflight que o servico externo nao trata (quebrando a busca de CEP em producao).
		if (/^https?:\/\//i.test(request.url) && !request.url.startsWith(environment.apiUrl)) {
			return next.handle(request);
		}

		const ignorarAuth = ROTAS_SEM_AUTH.some((rota) => request.url.includes(rota));
		const token = this.localStorageService.getToken();

		// Identifica a plataforma de origem para a telemetria (registro de login no backend).
		const headers: Record<string, string> = { 'X-Client-Platform': 'WEB' };
		if (!ignorarAuth && token) {
			headers['Authorization'] = `Bearer ${token}`;
		}
		const requisicao = request.clone({ setHeaders: headers });

		return next.handle(requisicao).pipe(
			catchError((error: HttpErrorResponse) => {
				if (!ignorarAuth && (error.status === 401 || error.status === 403) && token) {
					const returnUrl = this.router.url;
					this.localStorageService.clear();
					this.notificacoesService.info('Sua sessão expirou. Faça login novamente.', 'Login necessário');
					this.router.navigate(['/login'], { queryParams: { returnUrl } });
				}
				// Normaliza o erro para .message: a mensagem amigavel do backend chega em error.error.message,
				// mas todo consumidor deve ler so erro?.message a partir daqui.
				return throwError(() => ({ message: (error.error as { message?: string } | null)?.message }));
			}),
		);
	}
}
