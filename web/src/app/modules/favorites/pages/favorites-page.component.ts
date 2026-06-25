import { Component, OnInit, Signal, signal } from '@angular/core';
import { Router } from '@angular/router';
import { NotificacoesService } from '../../../services/notificacoes.service';
import { MenuItem } from '../../menu/_modelos/menu-item.model';
import { FavoritesService } from '../_services/favorites.service';

@Component({
	selector: 'app-favorites-page',
	standalone: false,
	templateUrl: './favorites-page.component.html',
	styleUrl: './favorites-page.component.scss',
})
export class FavoritesPageComponent implements OnInit {
	readonly favoritos: Signal<MenuItem[]>;
	readonly carregando = signal(true);

	constructor(
		private readonly favoritesService: FavoritesService,
		private readonly notificacoesService: NotificacoesService,
		private readonly router: Router,
	) {
		this.favoritos = this.favoritesService.favoritos;
	}

	ngOnInit(): void {
		this.favoritesService.carregar().subscribe({
			next: () => this.carregando.set(false),
			error: () => this.carregando.set(false),
		});
	}

	primeiraImagem(item: MenuItem): string | null {
		return item.images.length > 0 ? item.images[0].url : null;
	}

	abrirDetalhe(item: MenuItem): void {
		this.router.navigate(['/menu', item.id]);
	}

	desfavoritar(item: MenuItem, event: Event): void {
		event.stopPropagation();
		this.favoritesService.alternar(item).subscribe({
			error: (erro) => this.notificacoesService.erro(erro?.message ?? 'Não foi possível atualizar os favoritos.'),
		});
	}
}
