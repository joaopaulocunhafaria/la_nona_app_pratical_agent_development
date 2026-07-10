import { Component, OnInit, signal } from '@angular/core';
import { NotificacoesService } from '../../../../services/notificacoes.service';
import {
	LoginMetrics,
	MenuViewMetrics,
	OnlineCount,
	Periodo,
	SessionDurations,
	TelemetriaService,
	TopItem,
} from '../_services/telemetria.service';

type Granularidade = 'hour' | 'day';

@Component({
	selector: 'app-telemetria-page',
	standalone: false,
	templateUrl: './telemetria-page.component.html',
	styleUrl: './telemetria-page.component.scss',
})
export class TelemetriaPageComponent implements OnInit {
	// --- Online agora ---
	readonly online = signal<OnlineCount | null>(null);
	readonly carregandoOnline = signal(false);
	readonly onlineChart = signal<unknown>(null);

	// --- Logins por periodo ---
	loginsDe: Date = this.diasAtras(7);
	loginsAte: Date = this.fimDeHoje();
	granularidade: Granularidade = 'day';
	readonly granularidades = [
		{ label: 'Por dia', value: 'day' as Granularidade },
		{ label: 'Por hora', value: 'hour' as Granularidade },
	];
	readonly logins = signal<LoginMetrics | null>(null);
	readonly carregandoLogins = signal(false);
	readonly loginsChart = signal<unknown>(null);

	// --- Acessos ao cardapio (/menu) ---
	acessosDe: Date = this.diasAtras(7);
	acessosAte: Date = this.fimDeHoje();
	granularidadeAcessos: Granularidade = 'day';
	readonly acessos = signal<MenuViewMetrics | null>(null);
	readonly carregandoAcessos = signal(false);
	readonly acessosChart = signal<unknown>(null);

	// --- Tempo de acesso ---
	sessoesDe: Date = this.diasAtras(7);
	sessoesAte: Date = this.fimDeHoje();
	readonly sessoes = signal<SessionDurations | null>(null);
	readonly carregandoSessoes = signal(false);
	readonly sessoesChart = signal<unknown>(null);

	// --- Itens mais vistos ---
	itensDe: Date = this.diasAtras(7);
	itensAte: Date = this.fimDeHoje();
	readonly itens = signal<TopItem[]>([]);
	readonly carregandoItens = signal(false);
	readonly itensChart = signal<unknown>(null);

	// responsive + maintainAspectRatio:false: o canvas preenche o container de altura
	// fixa (h-64/h-40) em vez de derivar a altura da largura. Sem isto, no desktop (secao
	// larga) o grafico calcula uma altura enorme e transborda sobre a proxima secao; no
	// celular a largura pequena mascarava o problema.
	readonly opcoesBarra = {
		responsive: true,
		maintainAspectRatio: false,
		plugins: { legend: { display: false } },
		scales: { y: { beginAtZero: true } },
	};
	readonly opcoesBarraHorizontal = {
		responsive: true,
		maintainAspectRatio: false,
		indexAxis: 'y',
		plugins: { legend: { display: false } },
		scales: { x: { beginAtZero: true } },
	};
	readonly opcoesDoughnut = {
		responsive: true,
		maintainAspectRatio: false,
		plugins: { legend: { display: false } },
	};

	constructor(
		private readonly telemetriaService: TelemetriaService,
		private readonly notificacoesService: NotificacoesService,
	) {}

	ngOnInit(): void {
		this.carregarOnline();
		this.carregarLogins();
		this.carregarAcessos();
		this.carregarSessoes();
		this.carregarItens();
	}

	carregarOnline(): void {
		this.carregandoOnline.set(true);
		this.telemetriaService.online().subscribe({
			next: (dados) => {
				this.online.set(dados);
				this.onlineChart.set({
					labels: ['Logados', 'Anônimos'],
					datasets: [{ data: [dados.loggedIn, dados.anonymous], backgroundColor: ['#2e7d32', '#9e9e9e'] }],
				});
				this.carregandoOnline.set(false);
			},
			error: (erro) => {
				this.carregandoOnline.set(false);
				this.notificacoesService.erro(erro?.message ?? 'Não foi possível carregar os usuários online.');
			},
		});
	}

	carregarLogins(): void {
		this.carregandoLogins.set(true);
		this.telemetriaService.logins(this.periodo(this.loginsDe, this.loginsAte), this.granularidade).subscribe({
			next: (dados) => {
				this.logins.set(dados);
				this.loginsChart.set({
					labels: dados.series.map((b) => this.formatarBucket(b.bucket, this.granularidade)),
					datasets: [
						{
							label: 'Logins',
							data: dados.series.map((b) => b.count),
							borderColor: '#2e7d32',
							backgroundColor: 'rgba(46, 125, 50, 0.2)',
							fill: true,
							tension: 0.3,
						},
					],
				});
				this.carregandoLogins.set(false);
			},
			error: (erro) => {
				this.carregandoLogins.set(false);
				this.notificacoesService.erro(erro?.message ?? 'Não foi possível carregar os logins por período.');
			},
		});
	}

	carregarAcessos(): void {
		this.carregandoAcessos.set(true);
		this.telemetriaService.acessosMenu(this.periodo(this.acessosDe, this.acessosAte), this.granularidadeAcessos).subscribe({
			next: (dados) => {
				this.acessos.set(dados);
				this.acessosChart.set({
					labels: dados.series.map((b) => this.formatarBucket(b.bucket, this.granularidadeAcessos)),
					datasets: [
						{
							label: 'Acessos',
							data: dados.series.map((b) => b.count),
							borderColor: '#8d6e63',
							backgroundColor: 'rgba(141, 110, 59, 0.2)',
							fill: true,
							tension: 0.3,
						},
					],
				});
				this.carregandoAcessos.set(false);
			},
			error: (erro) => {
				this.carregandoAcessos.set(false);
				this.notificacoesService.erro(erro?.message ?? 'Não foi possível carregar os acessos ao cardápio.');
			},
		});
	}

	carregarSessoes(): void {
		this.carregandoSessoes.set(true);
		this.telemetriaService.sessoes(this.periodo(this.sessoesDe, this.sessoesAte)).subscribe({
			next: (dados) => {
				this.sessoes.set(dados);
				this.sessoesChart.set({
					labels: dados.ranking.map((u) => u.label),
					datasets: [
						{
							label: 'Minutos',
							data: dados.ranking.map((u) => Math.round((u.totalActiveSeconds / 60) * 10) / 10),
							backgroundColor: dados.ranking.map((u) => (u.anonymous ? '#9e9e9e' : '#2e7d32')),
						},
					],
				});
				this.carregandoSessoes.set(false);
			},
			error: (erro) => {
				this.carregandoSessoes.set(false);
				this.notificacoesService.erro(erro?.message ?? 'Não foi possível carregar o tempo de acesso.');
			},
		});
	}

	carregarItens(): void {
		this.carregandoItens.set(true);
		this.telemetriaService.itensMaisVistos(this.periodo(this.itensDe, this.itensAte)).subscribe({
			next: (dados) => {
				this.itens.set(dados);
				this.itensChart.set({
					labels: dados.map((i) => i.name),
					datasets: [{ label: 'Visualizações', data: dados.map((i) => i.views), backgroundColor: '#2e7d32' }],
				});
				this.carregandoItens.set(false);
			},
			error: (erro) => {
				this.carregandoItens.set(false);
				this.notificacoesService.erro(erro?.message ?? 'Não foi possível carregar os itens mais visualizados.');
			},
		});
	}

	/** Media de tempo ativo formatada em minutos. */
	mediaMinutos(): string {
		const seg = this.sessoes()?.avgActiveSeconds ?? 0;
		return (seg / 60).toFixed(1);
	}

	private periodo(de: Date | null, ate: Date | null): Periodo {
		return { from: de?.toISOString(), to: ate?.toISOString() };
	}

	private formatarBucket(iso: string, granularidade: Granularidade): string {
		const d = new Date(iso);
		const data = d.toLocaleDateString('pt-BR', { day: '2-digit', month: '2-digit' });
		return granularidade === 'hour' ? `${data} ${String(d.getHours()).padStart(2, '0')}h` : data;
	}

	private diasAtras(dias: number): Date {
		const d = new Date();
		d.setDate(d.getDate() - dias);
		d.setHours(0, 0, 0, 0);
		return d;
	}

	/**
	 * Fim do dia de hoje (23:59:59). O limite "Até" precisa cobrir o dia
	 * inteiro: se usassemos o instante de carregamento da pagina (new Date()),
	 * qualquer login/sessao/visualizacao que ocorresse depois de abrir o
	 * dashboard ficaria fora do filtro `BETWEEN from AND to`, e nem o botao
	 * "Atualizar" traria os novos eventos (o `to` continuaria congelado).
	 */
	private fimDeHoje(): Date {
		const d = new Date();
		d.setHours(23, 59, 59, 999);
		return d;
	}
}
