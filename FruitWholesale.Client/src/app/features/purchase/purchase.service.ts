import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { PaginatedList, PaginationRequest } from '../../core/models/common.model';
import { Purchase, PurchaseListItem, SavePurchase } from '../../core/models/transactions.model';
import { toHttpParams } from '../../core/utils/http-params.util';

@Injectable({ providedIn: 'root' })
export class PurchaseService {
  private readonly baseUrl = `${environment.apiUrl}/purchase`;

  constructor(private readonly http: HttpClient) {}

  getPaged(request: PaginationRequest, supplierId?: number | null, fromDate?: string | null, toDate?: string | null) {
    return this.http.get<PaginatedList<PurchaseListItem>>(this.baseUrl, {
      params: toHttpParams({ ...request, supplierId, fromDate, toDate })
    });
  }

  getById(id: number): Observable<Purchase> {
    return this.http.get<Purchase>(`${this.baseUrl}/${id}`);
  }

  getNextInvoiceNo(): Observable<string> {
    return this.http.get(`${this.baseUrl}/next-invoice-no`, { responseType: 'text' });
  }

  create(dto: SavePurchase): Observable<Purchase> {
    return this.http.post<Purchase>(this.baseUrl, dto);
  }

  update(id: number, dto: SavePurchase): Observable<Purchase> {
    return this.http.put<Purchase>(`${this.baseUrl}/${id}`, dto);
  }

  delete(id: number): Observable<void> {
    return this.http.delete<void>(`${this.baseUrl}/${id}`);
  }
}
