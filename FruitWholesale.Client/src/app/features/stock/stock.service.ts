import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { PaginatedList, PaginationRequest } from '../../core/models/common.model';
import { CurrentStock, StockAdjustment, StockLedgerEntry } from '../../core/models/stock.model';
import { toHttpParams } from '../../core/utils/http-params.util';

@Injectable({ providedIn: 'root' })
export class StockService {
  private readonly baseUrl = `${environment.apiUrl}/stock`;

  constructor(private readonly http: HttpClient) {}

  getCurrentStock(): Observable<CurrentStock[]> {
    return this.http.get<CurrentStock[]>(`${this.baseUrl}/current`);
  }

  getStockLedger(fruitId: number, request: PaginationRequest, fromDate?: string | null, toDate?: string | null) {
    return this.http.get<PaginatedList<StockLedgerEntry>>(`${this.baseUrl}/ledger/${fruitId}`, {
      params: toHttpParams({ ...request, fromDate, toDate })
    });
  }

  applyAdjustment(dto: StockAdjustment): Observable<void> {
    return this.http.post<void>(`${this.baseUrl}/adjustment`, dto);
  }
}
