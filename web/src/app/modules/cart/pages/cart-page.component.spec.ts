import { registerLocaleData } from '@angular/common';
import localePt from '@angular/common/locales/pt';
import { NO_ERRORS_SCHEMA, signal } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { Router } from '@angular/router';
import { of } from 'rxjs';

// O BrlPipe formata moeda em pt-BR; registramos o locale como no AppModule.
registerLocaleData(localePt);

import { AuthService } from '../../../services/auth.service';
import { ChatService } from '../../../services/chat.service';
import { NotificacoesService } from '../../../services/notificacoes.service';
import { UsuarioResponse } from '../../../services/auth.models';
import { SharedModule } from '../../../utils/shared.module';
import { MenuItem } from '../../menu/_modelos/menu-item.model';
import { Cart, CartItem } from '../_modelos/cart.model';
import { CartService } from '../_services/cart.service';
import { CartPageComponent } from './cart-page.component';

function criarItem(id: string, name: string, price: number, quantity: number): CartItem {
	return {
		id,
		menuItem: { id: `m-${id}`, name, price, images: [] } as unknown as MenuItem,
		quantity,
		addedAt: '',
		subtotal: price * quantity,
	};
}

function criarUsuario(): UsuarioResponse {
	return {
		id: 'user-1',
		email: 'joao@lanona.com',
		name: 'João',
		photo: null,
		provider: 'local',
		role: 'cliente',
		isAdmin: false,
		onboardingCompleted: true,
		address: {
			cep: '01001-000',
			rua: 'Rua das Flores',
			bairro: 'Centro',
			numero: '123',
			cidade: 'São Paulo',
			estado: 'SP',
			complemento: null,
		},
		createdAt: '',
		updatedAt: '',
	};
}

describe('CartPageComponent', () => {
	let component: CartPageComponent;
	let fixture: ComponentFixture<CartPageComponent>;

	const carrinho = signal<Cart>({ items: [], total: 0 });
	const usuario = signal<UsuarioResponse | null>(criarUsuario());

	const cartServiceStub = {
		cart: carrinho,
		carregar: jasmine.createSpy('carregar').and.returnValue(of(carrinho())),
		limpar: jasmine.createSpy('limpar').and.returnValue(of(undefined)),
		atualizarQuantidade: jasmine.createSpy('atualizarQuantidade').and.returnValue(of(carrinho())),
		remover: jasmine.createSpy('remover').and.returnValue(of(carrinho())),
	};
	const chatServiceStub = {
		conectar: jasmine.createSpy('conectar'),
		enviarMensagem: jasmine.createSpy('enviarMensagem'),
	};
	const authServiceStub = { usuario: () => usuario() };
	const notificacoesStub = {
		sucesso: jasmine.createSpy('sucesso'),
		erro: jasmine.createSpy('erro'),
		info: jasmine.createSpy('info'),
	};
	const routerStub = { navigate: jasmine.createSpy('navigate') };

	beforeEach(async () => {
		carrinho.set({
			items: [criarItem('1', 'X-Burguer', 20, 2), criarItem('2', 'Coca-Cola', 6, 1)],
			total: 46,
		});
		usuario.set(criarUsuario());
		chatServiceStub.conectar.calls.reset();
		chatServiceStub.enviarMensagem.calls.reset();
		cartServiceStub.limpar.calls.reset();
		routerStub.navigate.calls.reset();

		await TestBed.configureTestingModule({
			declarations: [CartPageComponent],
			imports: [SharedModule],
			schemas: [NO_ERRORS_SCHEMA],
			providers: [
				{ provide: CartService, useValue: cartServiceStub },
				{ provide: ChatService, useValue: chatServiceStub },
				{ provide: AuthService, useValue: authServiceStub },
				{ provide: NotificacoesService, useValue: notificacoesStub },
				{ provide: Router, useValue: routerStub },
			],
		}).compileComponents();

		fixture = TestBed.createComponent(CartPageComponent);
		component = fixture.componentInstance;
		fixture.detectChanges();
	});

	it('should create', () => {
		expect(component).toBeTruthy();
	});

	it('finalizarPedido abre o modal de confirmação', () => {
		expect(component.mostrarConfirmacao()).toBeFalse();
		component.finalizarPedido();
		expect(component.mostrarConfirmacao()).toBeTrue();
	});

	it('confirmarPedido envia o resumo no chat, limpa o carrinho e navega', () => {
		component.confirmarPedido();

		expect(chatServiceStub.conectar).toHaveBeenCalled();
		expect(chatServiceStub.enviarMensagem).toHaveBeenCalledTimes(1);

		const [userId, texto] = chatServiceStub.enviarMensagem.calls.mostRecent().args;
		expect(userId).toBe('user-1');
		expect(texto).toContain('João');
		expect(texto).toContain('2x X-Burguer');
		expect(texto).toContain('1x Coca-Cola');
		expect(texto).toContain('Rua das Flores');
		expect(texto).toContain('Total:');

		expect(component.mostrarConfirmacao()).toBeFalse();
		expect(cartServiceStub.limpar).toHaveBeenCalled();
		expect(routerStub.navigate).toHaveBeenCalledWith(['/chat']);
	});

	it('confirmarPedido bloqueia quando não há usuário logado', () => {
		usuario.set(null);

		component.confirmarPedido();

		expect(chatServiceStub.enviarMensagem).not.toHaveBeenCalled();
		expect(notificacoesStub.erro).toHaveBeenCalled();
	});
});
