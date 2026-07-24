import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { environment } from '../../../environments/environment';
import {
  BusinessProfitTotal,
  FruitProfitSummaryRow,
  ShopDailyProfitRow,
  ShopFruitProfitRow,
  ShopProfitSummaryRow
} from '../../core/models/profit.model';
import { toHttpParams } from '../../core/utils/http-params.util';

@Injectable({ providedIn: 'root' })
export class ProfitService {
  private readonly baseUrl = `${environment.apiUrl}/profit`;

  constructor(private readonly http: HttpClient) {}

  getShopDailyProfit(shopId: number | null, fromDate?: string, toDate?: string) {
    return this.http.get<ShopDailyProfitRow[]>(`${this.baseUrl}/shop-daily`, { params: toHttpParams({ shopId, fromDate, toDate }) });
  }

  getShopProfitSummary(fromDate?: string, toDate?: string) {
    return this.http.get<ShopProfitSummaryRow[]>(`${this.baseUrl}/shop-summary`, { params: toHttpParams({ fromDate, toDate }) });
  }

  getFruitProfitSummary(fromDate?: string, toDate?: string) {
    return this.http.get<FruitProfitSummaryRow[]>(`${this.baseUrl}/fruit-summary`, { params: toHttpParams({ fromDate, toDate }) });
  }

  getShopFruitProfit(shopId: number | null, fromDate?: string, toDate?: string) {
    return this.http.get<ShopFruitProfitRow[]>(`${this.baseUrl}/shop-fruit`, { params: toHttpParams({ shopId, fromDate, toDate }) });
  }

  getBusinessTotalProfit() {
    return this.http.get<BusinessProfitTotal>(`${this.baseUrl}/business-total`);
  }
}
