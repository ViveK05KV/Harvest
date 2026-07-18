import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { environment } from '../../../environments/environment';
import {
  DailyCollectionReportRow,
  DailyExpenseReportRow,
  DailySalesReportRow,
  FruitSalesReportRow,
  OutstandingReportRow,
  ProfitSummaryReportRow,
  PurchaseReportRow
} from '../../core/models/report.model';
import { toHttpParams } from '../../core/utils/http-params.util';

@Injectable({ providedIn: 'root' })
export class ReportService {
  private readonly baseUrl = `${environment.apiUrl}/report`;

  constructor(private readonly http: HttpClient) {}

  getDailySales(fromDate: string, toDate: string, shopId?: number | null) {
    return this.http.get<DailySalesReportRow[]>(`${this.baseUrl}/daily-sales`, { params: toHttpParams({ fromDate, toDate, shopId }) });
  }

  getDailyCollection(fromDate: string, toDate: string, shopId?: number | null) {
    return this.http.get<DailyCollectionReportRow[]>(`${this.baseUrl}/daily-collection`, {
      params: toHttpParams({ fromDate, toDate, shopId })
    });
  }

  getDailyExpense(fromDate: string, toDate: string, expenseCategoryId?: number | null) {
    return this.http.get<DailyExpenseReportRow[]>(`${this.baseUrl}/daily-expense`, {
      params: toHttpParams({ fromDate, toDate, expenseCategoryId })
    });
  }

  getPurchaseReport(fromDate: string, toDate: string, supplierId?: number | null) {
    return this.http.get<PurchaseReportRow[]>(`${this.baseUrl}/purchase`, { params: toHttpParams({ fromDate, toDate, supplierId }) });
  }

  getFruitSales(fromDate: string, toDate: string) {
    return this.http.get<FruitSalesReportRow[]>(`${this.baseUrl}/fruit-sales`, { params: toHttpParams({ fromDate, toDate }) });
  }

  getOutstanding() {
    return this.http.get<OutstandingReportRow[]>(`${this.baseUrl}/outstanding`);
  }

  getProfitSummary(fromDate: string, toDate: string) {
    return this.http.get<ProfitSummaryReportRow[]>(`${this.baseUrl}/profit-summary`, { params: toHttpParams({ fromDate, toDate }) });
  }
}
