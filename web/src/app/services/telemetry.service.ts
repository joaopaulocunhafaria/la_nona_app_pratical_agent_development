import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { environment } from '../../environments/environment';

interface SessionStartResponse {
	sessionId: string;
}

/**
 * Coleta de telemetria de uso no app web. Cria uma sessao ao abrir, conta o
 * tempo ativo (apenas com a aba visivel e em foco), envia heartbeats e marca o
 * fim ao fechar/descarregar a pagina. Identifica anonimos por um id local; o
 * usuario logado e' associado no backend via JWT (anexado pelo AuthInterceptor).
 *
 * Toda chamada e' best-effort: falhas de telemetria sao silenciosas e nunca
 * afetam a experiencia do usuario.
 */
@Injectable({ providedIn: 'root' })
export class TelemetryService {
	private readonly baseUrl = `${environment.apiUrl}/telemetry`;
	private readonly anonymousKey = 'telemetryAnonymousId';
	private readonly heartbeatIntervalMs = 30_000;

	private sessionId: string | null = null;
	private activeSeconds = 0;
	private tickTimer?: ReturnType<typeof setInterval>;
	private heartbeatTimer?: ReturnType<typeof setInterval>;
	private iniciado = false;

	constructor(private readonly http: HttpClient) {}

	/** Inicia a coleta. Idempotente: chamadas repetidas sao ignoradas. */
	iniciar(): void {
		if (this.iniciado || typeof window === 'undefined') {
			return;
		}
		this.iniciado = true;

		this.http
			.post<SessionStartResponse>(`${this.baseUrl}/sessions`, {
				anonymousId: this.anonymousId(),
				platform: 'WEB',
			})
			.subscribe({
				next: (res) => (this.sessionId = res.sessionId),
				error: () => undefined,
			});

		// Conta o tempo ativo a cada segundo, somente com a aba visivel e em foco.
		this.tickTimer = setInterval(() => {
			if (document.visibilityState === 'visible' && document.hasFocus()) {
				this.activeSeconds++;
			}
		}, 1000);

		this.heartbeatTimer = setInterval(() => this.enviarHeartbeat(), this.heartbeatIntervalMs);

		// Ao esconder a aba, envia um heartbeat final confiavel (sem encerrar a
		// sessao, pois o usuario pode voltar). Ao descarregar, encerra a sessao.
		document.addEventListener('visibilitychange', () => {
			if (document.visibilityState === 'hidden') {
				this.enviarBeacon(`${this.baseUrl}/sessions/${this.sessionId}/heartbeat`);
			}
		});
		window.addEventListener('pagehide', () => this.encerrar());
	}

	/**
	 * Registra um acesso a aba de cardapio (/menu). Deve ser chamado a cada
	 * navegacao para a lista, sem deduplicar: ir para a home e voltar conta de
	 * novo. Logado ou anonimo (o usuario e' associado no backend via JWT).
	 */
	registrarAcessoMenu(): void {
		this.http
			.post<void>(`${this.baseUrl}/menu-views`, {
				anonymousId: this.anonymousId(),
				platform: 'WEB',
			})
			.subscribe({ error: () => undefined });
	}

	/** Registra a visualizacao do detalhe de um item do cardapio. */
	registrarVisualizacaoItem(menuItemId: string): void {
		this.http
			.post<void>(`${this.baseUrl}/item-views`, {
				menuItemId,
				anonymousId: this.anonymousId(),
				platform: 'WEB',
			})
			.subscribe({ error: () => undefined });
	}

	private enviarHeartbeat(): void {
		if (!this.sessionId) {
			return;
		}
		this.http
			.post<void>(`${this.baseUrl}/sessions/${this.sessionId}/heartbeat`, { activeSeconds: this.activeSeconds })
			.subscribe({ error: () => undefined });
	}

	private encerrar(): void {
		this.enviarBeacon(`${this.baseUrl}/sessions/${this.sessionId}/end`);
	}

	/** Envio confiavel durante visibilitychange/pagehide via sendBeacon. */
	private enviarBeacon(url: string): void {
		if (!this.sessionId || !navigator.sendBeacon) {
			return;
		}
		const payload = new Blob([JSON.stringify({ activeSeconds: this.activeSeconds })], {
			type: 'application/json',
		});
		navigator.sendBeacon(url, payload);
	}

	private anonymousId(): string {
		let id = localStorage.getItem(this.anonymousKey);
		if (!id) {
			id = crypto.randomUUID();
			localStorage.setItem(this.anonymousKey, id);
		}
		return id;
	}
}
