import { Component, OnInit, Signal, signal } from '@angular/core';
import { Router } from '@angular/router';
import { AuthService } from '../../../services/auth.service';
import { ChatService } from '../../../services/chat.service';
import { NotificacoesService } from '../../../services/notificacoes.service';
import { BrlPipe } from '../../../utils/_pipes/brl.pipe';
import { Cart, CartItem } from '../_modelos/cart.model';
import { CartService } from '../_services/cart.service';

@Component({
	selector: 'app-cart-page',
	standalone: false,
	templateUrl: './cart-page.component.html',
	styleUrl: './cart-page.component.scss',
})
export class CartPageComponent implements OnInit {
	readonly cart: Signal<Cart>;
	readonly carregando = signal(true);
	readonly mostrarConfirmacao = signal(false);

	private readonly brlPipe = new BrlPipe();

	constructor(
		private readonly cartService: CartService,
		private readonly authService: AuthService,
		private readonly chatService: ChatService,
		private readonly notificacoesService: NotificacoesService,
		private readonly router: Router,
	) {
		this.cart = this.cartService.cart;
	}

	ngOnInit(): void {
		this.cartService.carregar().subscribe({
			next: () => this.carregando.set(false),
			error: () => this.carregando.set(false),
		});
	}

	primeiraImagem(item: CartItem): string | null {
		return item.menuItem.images.length > 0 ? item.menuItem.images[0].url : null;
	}

	diminuir(item: CartItem): void {
		const novaQuantidade = item.quantity - 1;
		if (novaQuantidade <= 0) {
			this.remover(item);
			return;
		}
		this.cartService.atualizarQuantidade(item.menuItem.id, novaQuantidade).subscribe();
	}

	aumentar(item: CartItem): void {
		this.cartService.atualizarQuantidade(item.menuItem.id, item.quantity + 1).subscribe();
	}

	remover(item: CartItem): void {
		this.cartService.remover(item.menuItem.id).subscribe();
	}

	finalizarPedido(): void {
		if (this.cart().items.length === 0) {
			return;
		}
		this.mostrarConfirmacao.set(true);
	}

	confirmarPedido(): void {
		const usuario = this.authService.usuario();
		if (!usuario) {
			this.notificacoesService.erro('Você precisa estar logado para finalizar o pedido.');
			return;
		}

		// Envia o resumo do pedido na propria thread de suporte do cliente; o admin
		// recebe essa mensagem no chat (mesmo canal usado pelo atendimento).
		this.chatService.conectar();
		this.chatService.enviarMensagem(usuario.id, this.montarMensagemPedido());
		this.mostrarConfirmacao.set(false);

		this.cartService.limpar().subscribe({
			next: () => {
				this.notificacoesService.sucesso('Pedido enviado! Acompanhe pelo chat.');
				this.router.navigate(['/chat']);
			},
			error: (erro) => this.notificacoesService.erro(erro?.message ?? 'Não foi possível finalizar o pedido.'),
		});
	}

	private montarMensagemPedido(): string {
		const usuario = this.authService.usuario();
		const nome = usuario?.name?.trim() || 'Cliente';

		const linhas: string[] = [`Olá! Aqui é ${nome}, gostaria de fazer um pedido.`];

		const endereco = this.enderecoFormatado();
		if (endereco) {
			linhas.push(`Endereço de entrega: ${endereco}`);
		}

		linhas.push('', 'Itens do pedido:');
		for (const item of this.cart().items) {
			linhas.push(`• ${item.quantity}x ${item.menuItem.name} — ${this.brlPipe.transform(item.subtotal)}`);
		}
		linhas.push('', `Total: ${this.brlPipe.transform(this.cart().total)}`);

		return linhas.join('\n');
	}

	private enderecoFormatado(): string | null {
		const endereco = this.authService.usuario()?.address;
		if (!endereco) {
			return null;
		}
		const ruaNumero = [endereco.rua, endereco.numero].filter((parte) => parte?.trim()).join(', ');
		const cidadeEstado = [endereco.bairro, endereco.cidade, endereco.estado].filter((parte) => parte?.trim()).join(' - ');
		const partes = [ruaNumero, cidadeEstado, endereco.cep, endereco.complemento]
			.map((parte) => parte?.trim())
			.filter((parte): parte is string => !!parte);
		return partes.length > 0 ? partes.join(' • ') : null;
	}
}
