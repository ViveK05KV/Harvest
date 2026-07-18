import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { PaginatedList, PaginationRequest } from '../../core/models/common.model';
import { SaveSupply, Supply, SupplyListItem } from '../../core/models/transactions.model';
import { toHttpParams } from '../../core/utils/http-params.util';

@Injectable({ providedIn: 'root' })
export class SupplyService {
  private readonly baseUrl = `${environment.apiUrl}/supply`;

  constructor(private readonly http: HttpClient) {}

  getPaged(request: PaginationRequest, shopId?: number | null, fromDate?: string | null, toDate?: string | null) {
    return this.http.get<PaginatedList<SupplyListItem>>(this.baseUrl, {
      params: toHttpParams({ ...request, shopId, fromDate, toDate })
    });
  }

  getById(id: number): Observable<Supply> {
    return this.http.get<Supply>(`${this.baseUrl}/${id}`);
  }

  getNextInvoiceNo(): Observable<string> {
    return this.http.get(`${this.baseUrl}/next-invoice-no`, { responseType: 'text' });
  }

  create(dto: SaveSupply): Observable<Supply> {
    return this.http.post<Supply>(this.baseUrl, dto);
  }

  update(id: number, dto: SaveSupply): Observable<Supply> {
    return this.http.put<Supply>(`${this.baseUrl}/${id}`, dto);
  }

  delete(id: number): Observable<void> {
    return this.http.delete<void>(`${this.baseUrl}/${id}`);
  }
}
