import { HttpClient, HttpParams } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { environment } from '../../../../../environments/environment';

export interface OnlineCount {
	loggedIn: number;
	anonymous: number;
}

export interface TimeBucket {
	bucket: string;
	count: number;
}

export interface LoginMetrics {
	total: number;
	distinctUsers: number;
	series: TimeBucket[];
}

export interface MenuViewMetrics {
	total: number;
	series: TimeBucket[];
}

export interface UserDuration {
	label: string;
	anonymous: boolean;
	totalActiveSeconds: number;
	sessionCount: number;
}

export interface SessionDurations {
	avgActiveSeconds: number;
	totalSessions: number;
	ranking: UserDuration[];
}

export interface TopItem {
	menuItemId: string;
	name: string;
	views: number;
}

export interface Periodo {
	from?: string;
	to?: string;
}

@Injectable({ providedIn: 'root' })
export class TelemetriaService {
	private readonly baseUrl = `${environment.apiUrl}/admin/telemetry`;

	constructor(private readonly http: HttpClient) {}

	online(): Observable<OnlineCount> {
		return this.http.get<OnlineCount>(`${this.baseUrl}/online`);
	}

	logins(periodo: Periodo, granularity: 'hour' | 'day'): Observable<LoginMetrics> {
		const params = this.comPeriodo(periodo).set('granularity', granularity);
		return this.http.get<LoginMetrics>(`${this.baseUrl}/logins`, { params });
	}

	acessosMenu(periodo: Periodo, granularity: 'hour' | 'day'): Observable<MenuViewMetrics> {
		const params = this.comPeriodo(periodo).set('granularity', granularity);
		return this.http.get<MenuViewMetrics>(`${this.baseUrl}/menu-views`, { params });
	}

	sessoes(periodo: Periodo, limit = 20): Observable<SessionDurations> {
		const params = this.comPeriodo(periodo).set('limit', String(limit));
		return this.http.get<SessionDurations>(`${this.baseUrl}/sessions`, { params });
	}

	itensMaisVistos(periodo: Periodo, limit = 10): Observable<TopItem[]> {
		const params = this.comPeriodo(periodo).set('limit', String(limit));
		return this.http.get<TopItem[]>(`${this.baseUrl}/top-items`, { params });
	}

	private comPeriodo(periodo: Periodo): HttpParams {
		let params = new HttpParams();
		if (periodo.from) {
			params = params.set('from', periodo.from);
		}
		if (periodo.to) {
			params = params.set('to', periodo.to);
		}
		return params;
	}
}
