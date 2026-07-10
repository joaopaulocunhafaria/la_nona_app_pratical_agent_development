import { Component, OnInit, signal } from '@angular/core';
import { ActivatedRoute } from '@angular/router';
import { AuthPromptService } from '../../../services/auth-prompt.service';
import { AuthService } from '../../../services/auth.service';
import { NotificacoesService } from '../../../services/notificacoes.service';
import { CartService } from '../../cart/_services/cart.service';
import { FavoritesService } from '../../favorites/_services/favorites.service';
import { TelemetryService } from '../../../services/telemetry.service';
import { MenuItem, STATUS_LABELS, STATUS_SEVERITIES, podePedir } from '../_modelos/menu-item.model';
import { MenuItemService } from '../_services/menu-item.service';

@Component({
	selector: 'app-menu-detail',
	standalone: false,
	templateUrl: './menu-detail.component.html',
	styleUrl: './menu-detail.component.scss',
})
export class MenuDetailComponent implements OnInit {
	readonly item = signal<MenuItem | null>(null);
	readonly carregando = signal(true);

	constructor(
		private readonly route: ActivatedRoute,
		private readonly authService: AuthService,
		private readonly authPromptService: AuthPromptService,
		private readonly menuItemService: MenuItemService,
		private readonly favoritesService: FavoritesService,
		private readonly cartService: CartService,
		private readonly notificacoesService: NotificacoesService,
		private readonly telemetryService: TelemetryService,
	) {}

	ngOnInit(): void {
		const id = this.route.snapshot.paramMap.get('id')!;
		this.telemetryService.registrarVisualizacaoItem(id);
		this.menuItemService.buscarPorId(id).subscribe({
			next: (item) => {
				this.item.set(item);
				this.carregando.set(false);
			},
			error: () => this.carregando.set(false),
		});
		if (this.authService.isAuthenticated()) {
			this.favoritesService.carregar().subscribe();
		}
	}

	isFavorito(): boolean {
		const item = this.item();
		return !!item && this.favoritesService.isFavorito(item.id);
	}

	alternarFavorito(): void {
		const item = this.item();
		if (!item || !this.authPromptService.requererLogin()) {
			return;
		}
		this.favoritesService.alternar(item).subscribe({
			error: (erro) => this.notificacoesService.erro(erro?.message ?? 'Não foi possível atualizar os favoritos.'),
		});
	}

	adicionarAoCarrinho(): void {
		const item = this.item();
		if (!item || !this.authPromptService.requererLogin()) {
			return;
		}
		this.cartService.adicionar(item.id).subscribe({
			next: () => this.notificacoesService.sucesso('Item adicionado ao carrinho'),
			error: (erro) => this.notificacoesService.erro(erro?.message ?? 'Não foi possível adicionar ao carrinho.'),
		});
	}

	statusLabel(): string {
		const item = this.item();
		return item ? STATUS_LABELS[item.status] : '';
	}

	statusSeverity(): 'success' | 'info' | 'warn' | 'danger' {
		const item = this.item();
		return item ? STATUS_SEVERITIES[item.status] : 'success';
	}

	podePedir(): boolean {
		const item = this.item();
		return !!item && podePedir(item.status);
	}

	imagens(): string[] {
		return (
			this.item()
				?.images.sort((a, b) => a.position - b.position)
				.map((image) => image.url) ?? []
		);
	}
}
