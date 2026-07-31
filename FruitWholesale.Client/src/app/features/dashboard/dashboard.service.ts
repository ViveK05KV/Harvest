import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { DashboardCharts, DashboardPeriod, DashboardSummary, SalesVsPurchases, TrendPoint } from '../../core/models/dashboard.model';

@Injectable({ providedIn: 'root' })
export class DashboardService {
  private readonly baseUrl = `${environment.apiUrl}/dashboard`;

  constructor(private readonly http: HttpClient) {}

  getSummary(): Observable<DashboardSummary> {
    return this.http.get<DashboardSummary>(`${this.baseUrl}/summary`);
  }

  getCharts(): Observable<DashboardCharts> {
    return this.http.get<DashboardCharts>(`${this.baseUrl}/charts`);
  }

  getSalesTrend(period: DashboardPeriod): Observable<TrendPoint[]> {
    return this.http.get<TrendPoint[]>(`${this.baseUrl}/sales-trend`, { params: { period } });
  }

  getSalesVsPurchases(period: DashboardPeriod): Observable<SalesVsPurchases> {
    return this.http.get<SalesVsPurchases>(`${this.baseUrl}/sales-vs-purchases`, { params: { period } });
  }

  getCashTrend(): Observable<TrendPoint[]> {
    return this.http.get<TrendPoint[]>(`${this.baseUrl}/cash-trend`);
  }

  getProfitTrend(): Observable<TrendPoint[]> {
    return this.http.get<TrendPoint[]>(`${this.baseUrl}/profit-trend`);
  }
}
