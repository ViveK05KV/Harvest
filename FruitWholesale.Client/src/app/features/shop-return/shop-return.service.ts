import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { PaginatedList, PaginationRequest } from '../../core/models/common.model';
import { SaveShopReturn, ShopReturn, ShopReturnListItem } from '../../core/models/transactions.model';
import { toHttpParams } from '../../core/utils/http-params.util';

@Injectable({ providedIn: 'root' })
export class ShopReturnService {
  private readonly baseUrl = `${environment.apiUrl}/shopreturn`;

  constructor(private readonly http: HttpClient) {}

  getPaged(request: PaginationRequest, shopId?: number | null, fromDate?: string | null, toDate?: string | null) {
    return this.http.get<PaginatedList<ShopReturnListItem>>(this.baseUrl, {
      params: toHttpParams({ ...request, shopId, fromDate, toDate })
    });
  }

  getById(id: number): Observable<ShopReturn> {
    return this.http.get<ShopReturn>(`${this.baseUrl}/${id}`);
  }

  getNextReferenceNo(): Observable<string> {
    return this.http.get(`${this.baseUrl}/next-reference-no`, { responseType: 'text' });
  }

  create(dto: SaveShopReturn): Observable<ShopReturn> {
    return this.http.post<ShopReturn>(this.baseUrl, dto);
  }

  update(id: number, dto: SaveShopReturn): Observable<ShopReturn> {
    return this.http.put<ShopReturn>(`${this.baseUrl}/${id}`, dto);
  }

  delete(id: number): Observable<void> {
    return this.http.delete<void>(`${this.baseUrl}/${id}`);
  }
}
