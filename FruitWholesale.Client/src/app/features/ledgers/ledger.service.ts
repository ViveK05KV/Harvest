import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { environment } from '../../../environments/environment';
import { PaginatedList, PaginationRequest } from '../../core/models/common.model';
import { CashLedgerEntry, ShopLedgerEntry, SupplierLedgerEntry } from '../../core/models/ledger.model';
import { toHttpParams } from '../../core/utils/http-params.util';

@Injectable({ providedIn: 'root' })
export class LedgerService {
  private readonly baseUrl = `${environment.apiUrl}/ledger`;

  constructor(private readonly http: HttpClient) {}

  getShopLedger(shopId: number, request: PaginationRequest, fromDate?: string | null, toDate?: string | null) {
    return this.http.get<PaginatedList<ShopLedgerEntry>>(`${this.baseUrl}/shop/${shopId}`, {
      params: toHttpParams({ ...request, fromDate, toDate })
    });
  }

  getSupplierLedger(supplierId: number, request: PaginationRequest, fromDate?: string | null, toDate?: string | null) {
    return this.http.get<PaginatedList<SupplierLedgerEntry>>(`${this.baseUrl}/supplier/${supplierId}`, {
      params: toHttpParams({ ...request, fromDate, toDate })
    });
  }

  getCashLedger(request: PaginationRequest, fromDate?: string | null, toDate?: string | null, transactionType?: string | null) {
    return this.http.get<PaginatedList<CashLedgerEntry>>(`${this.baseUrl}/cash`, {
      params: toHttpParams({ ...request, fromDate, toDate, transactionType })
    });
  }
}
