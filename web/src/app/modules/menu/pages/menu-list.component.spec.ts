import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { NO_ERRORS_SCHEMA } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { provideRouter } from '@angular/router';
import { ConfirmationService, MessageService } from 'primeng/api';

import { environment } from '../../../../environments/environment';
import { SharedModule } from '../../../utils/shared.module';
import { MenuItem } from '../_modelos/menu-item.model';
import { MenuListComponent } from './menu-list.component';

function criarItem(id: string, name: string, category: string): MenuItem {
	return {
		id,
		name,
		description: '',
		price: 10,
		category,
		categoryId: `cat-${id}`,
		status: 'DISPONIVEL',
		images: [],
		createdAt: '',
		updatedAt: '',
	};
}

describe('MenuListComponent', () => {
	let component: MenuListComponent;
	let fixture: ComponentFixture<MenuListComponent>;
	let httpMock: HttpTestingController;

	const itens: MenuItem[] = [
		criarItem('1', 'X-Burguer', 'Hamburguer'),
		criarItem('2', 'Pizza Calabresa', 'Pizza'),
		criarItem('3', 'Coca-Cola', 'Bebida'),
	];

	beforeEach(async () => {
		await TestBed.configureTestingModule({
			declarations: [MenuListComponent],
			imports: [SharedModule],
			schemas: [NO_ERRORS_SCHEMA],
			providers: [provideHttpClient(), provideHttpClientTesting(), provideRouter([]), ConfirmationService, MessageService],
		}).compileComponents();

		fixture = TestBed.createComponent(MenuListComponent);
		component = fixture.componentInstance;
		httpMock = TestBed.inject(HttpTestingController);
		fixture.detectChanges();

		// ngOnInit dispara a listagem de itens e de categorias.
		httpMock.expectOne(`${environment.apiUrl}/menu-items`).flush(itens);
		httpMock.expectOne(`${environment.apiUrl}/menu-items/categories`).flush(['Hamburguer', 'Pizza', 'Bebida']);
	});

	afterEach(() => {
		httpMock.verify();
	});

	it('should create', () => {
		expect(component).toBeTruthy();
	});

	it('carrega itens e categorias no init', () => {
		expect(component.itens().length).toBe(3);
		expect(component.categorias()).toEqual(['Hamburguer', 'Pizza', 'Bebida']);
	});

	it('sem filtros exibe todos os itens', () => {
		expect(component.itensFiltrados().length).toBe(3);
	});

	it('filtra pela categoria selecionada', () => {
		component.selecionarCategoria('Pizza');
		expect(component.itensFiltrados().map((i) => i.name)).toEqual(['Pizza Calabresa']);
	});

	it('alterna a categoria ao clicar novamente (limpa o filtro)', () => {
		component.selecionarCategoria('Pizza');
		component.selecionarCategoria('Pizza');
		expect(component.categoriaSelecionada()).toBeNull();
		expect(component.itensFiltrados().length).toBe(3);
	});

	it('filtra por nome na busca (case-insensitive)', () => {
		component.atualizarBusca('coca');
		expect(component.itensFiltrados().map((i) => i.name)).toEqual(['Coca-Cola']);
	});

	it('quando a busca nao encontra nada, exibe todos os itens', () => {
		component.atualizarBusca('inexistente');
		expect(component.itensFiltrados().length).toBe(3);
	});

	it('combina categoria e busca, e cai para a categoria inteira quando a busca nao casa', () => {
		component.selecionarCategoria('Hamburguer');
		component.atualizarBusca('zzz');
		// busca sem resultado dentro da categoria -> mostra todos da categoria
		expect(component.itensFiltrados().map((i) => i.name)).toEqual(['X-Burguer']);
	});

	it('o arraste lateral ajusta o scrollLeft do container', () => {
		const elemento = { scrollLeft: 0 } as HTMLElement;
		component.iniciarArraste({ pageX: 100 } as MouseEvent, elemento);
		component.arrastar({ pageX: 60, preventDefault: () => {} } as MouseEvent, elemento);
		expect(elemento.scrollLeft).toBe(40);
	});
});
