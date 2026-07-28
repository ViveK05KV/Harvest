import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { PaginatedList, PaginationRequest } from '../../core/models/common.model';
import { SaveSupplierReturn, SupplierReturn, SupplierReturnListItem } from '../../core/models/transactions.model';
import { toHttpParams } from '../../core/utils/http-params.util';

@Injectable({ providedIn: 'root' })
export class SupplierReturnService {
  private readonly baseUrl = `${environment.apiUrl}/supplierreturn`;

  constructor(private readonly http: HttpClient) {}

  getPaged(request: PaginationRequest, supplierId?: number | null, fromDate?: string | null, toDate?: string | null) {
    return this.http.get<PaginatedList<SupplierReturnListItem>>(this.baseUrl, {
      params: toHttpParams({ ...request, supplierId, fromDate, toDate })
    });
  }

  getById(id: number): Observable<SupplierReturn> {
    return this.http.get<SupplierReturn>(`${this.baseUrl}/${id}`);
  }

  getNextReferenceNo(): Observable<string> {
    return this.http.get(`${this.baseUrl}/next-reference-no`, { responseType: 'text' });
  }

  create(dto: SaveSupplierReturn): Observable<SupplierReturn> {
    return this.http.post<SupplierReturn>(this.baseUrl, dto);
  }

  update(id: number, dto: SaveSupplierReturn): Observable<SupplierReturn> {
    return this.http.put<SupplierReturn>(`${this.baseUrl}/${id}`, dto);
  }

  delete(id: number): Observable<void> {
    return this.http.delete<void>(`${this.baseUrl}/${id}`);
  }
}
