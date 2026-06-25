import { Component, OnInit, Signal, computed, signal } from '@angular/core';
import { Router } from '@angular/router';
import { ConfirmationService } from 'primeng/api';
import { AuthPromptService } from '../../../services/auth-prompt.service';
import { AuthService } from '../../../services/auth.service';
import { NotificacoesService } from '../../../services/notificacoes.service';
import { CartService } from '../../cart/_services/cart.service';
import { FavoritesService } from '../../favorites/_services/favorites.service';
import { MenuItem } from '../_modelos/menu-item.model';
import { MenuItemService } from '../_services/menu-item.service';

@Component({
	selector: 'app-menu-list',
	standalone: false,
	templateUrl: './menu-list.component.html',
	styleUrl: './menu-list.component.scss',
})
export class MenuListComponent implements OnInit {
	readonly itens = signal<MenuItem[]>([]);
	readonly categorias = signal<string[]>([]);
	readonly categoriaSelecionada = signal<string | null>(null);
	readonly termoBusca = signal('');
	readonly carregando = signal(true);
	readonly erro = signal(false);

	/**
	 * Aplica o filtro de categoria e, em seguida, o termo de busca por nome.
	 * Se a busca nao retornar nenhum item, exibimos todos os itens (respeitando
	 * a categoria selecionada) em vez de uma lista vazia.
	 */
	readonly itensFiltrados = computed<MenuItem[]>(() => {
		const categoria = this.categoriaSelecionada();
		const base = categoria ? this.itens().filter((item) => item.category === categoria) : this.itens();

		const termo = this.termoBusca().trim().toLowerCase();
		if (!termo) {
			return base;
		}

		const encontrados = base.filter((item) => item.name.toLowerCase().includes(termo));
		return encontrados.length > 0 ? encontrados : base;
	});

	readonly isAdmin: Signal<boolean>;

	constructor(
		private readonly authService: AuthService,
		private readonly authPromptService: AuthPromptService,
		private readonly menuItemService: MenuItemService,
		private readonly favoritesService: FavoritesService,
		private readonly cartService: CartService,
		private readonly notificacoesService: NotificacoesService,
		private readonly confirmationService: ConfirmationService,
		private readonly router: Router,
	) {
		this.isAdmin = this.authService.isAdmin;
	}

	ngOnInit(): void {
		this.carregarItens();
		this.carregarCategorias();
		if (this.authService.isAuthenticated()) {
			this.favoritesService.carregar().subscribe();
		}
	}

	private carregarItens(): void {
		this.carregando.set(true);
		this.erro.set(false);
		this.menuItemService.listar().subscribe({
			next: (itens) => {
				this.itens.set(itens);
				this.carregando.set(false);
			},
			error: () => {
				this.erro.set(true);
				this.carregando.set(false);
			},
		});
	}

	private carregarCategorias(): void {
		this.menuItemService.listarCategorias().subscribe({
			next: (categorias) => this.categorias.set(categorias),
			error: () => this.categorias.set([]),
		});
	}

	atualizarBusca(termo: string): void {
		this.termoBusca.set(termo);
	}

	selecionarCategoria(categoria: string): void {
		this.categoriaSelecionada.update((atual) => (atual === categoria ? null : categoria));
	}

	limparCategoria(): void {
		this.categoriaSelecionada.set(null);
	}

	private arrastando = false;
	private posInicialX = 0;
	private scrollInicial = 0;

	iniciarArraste(event: MouseEvent, elemento: HTMLElement): void {
		this.arrastando = true;
		this.posInicialX = event.pageX;
		this.scrollInicial = elemento.scrollLeft;
	}

	arrastar(event: MouseEvent, elemento: HTMLElement): void {
		if (!this.arrastando) {
			return;
		}
		event.preventDefault();
		elemento.scrollLeft = this.scrollInicial - (event.pageX - this.posInicialX);
	}

	finalizarArraste(): void {
		this.arrastando = false;
	}

	isFavorito(item: MenuItem): boolean {
		return this.favoritesService.isFavorito(item.id);
	}

	alternarFavorito(item: MenuItem, event: Event): void {
		event.stopPropagation();
		if (!this.authPromptService.requererLogin()) {
			return;
		}
		this.favoritesService.alternar(item).subscribe({
			error: (erro) => this.notificacoesService.erro(erro?.message ?? 'Não foi possível atualizar os favoritos.'),
		});
	}

	adicionarAoCarrinho(item: MenuItem, event: Event): void {
		event.stopPropagation();
		if (!this.authPromptService.requererLogin()) {
			return;
		}
		this.cartService.adicionar(item.id).subscribe({
			next: () => this.notificacoesService.sucesso('Item adicionado ao carrinho'),
			error: (erro) => this.notificacoesService.erro(erro?.message ?? 'Não foi possível adicionar ao carrinho.'),
		});
	}

	abrirDetalhe(item: MenuItem): void {
		this.router.navigate(['/menu', item.id]);
	}

	novoItem(): void {
		this.router.navigate(['/menu/new']);
	}

	editarItem(item: MenuItem, event: Event): void {
		event.stopPropagation();
		this.router.navigate(['/menu', item.id, 'edit']);
	}

	excluirItem(item: MenuItem, event: Event): void {
		event.stopPropagation();
		this.confirmationService.confirm({
			header: 'Excluir item',
			message: `Tem certeza que deseja excluir "${item.name}"?`,
			acceptLabel: 'Excluir',
			rejectLabel: 'Cancelar',
			acceptButtonStyleClass: 'p-button-danger',
			accept: () => {
				this.menuItemService.excluir(item.id).subscribe({
					next: () => {
						this.itens.set(this.itens().filter((i) => i.id !== item.id));
						this.notificacoesService.sucesso('Item excluído com sucesso.');
					},
					error: (erro) => this.notificacoesService.erro(erro?.message ?? 'Não foi possível excluir o item.'),
				});
			},
		});
	}

	primeiraImagem(item: MenuItem): string | null {
		return item.images.length > 0 ? item.images[0].url : null;
	}
}
