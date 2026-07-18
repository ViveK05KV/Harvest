import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { PaginatedList, PaginationRequest } from '../../core/models/common.model';
import { SaveSupplierPayment, SupplierPayment } from '../../core/models/transactions.model';
import { toHttpParams } from '../../core/utils/http-params.util';

@Injectable({ providedIn: 'root' })
export class SupplierPaymentService {
  private readonly baseUrl = `${environment.apiUrl}/supplierpayment`;

  constructor(private readonly http: HttpClient) {}

  getPaged(request: PaginationRequest, supplierId?: number | null, fromDate?: string | null, toDate?: string | null) {
    return this.http.get<PaginatedList<SupplierPayment>>(this.baseUrl, {
      params: toHttpParams({ ...request, supplierId, fromDate, toDate })
    });
  }

  create(dto: SaveSupplierPayment): Observable<SupplierPayment> {
    return this.http.post<SupplierPayment>(this.baseUrl, dto);
  }

  update(id: number, dto: SaveSupplierPayment): Observable<SupplierPayment> {
    return this.http.put<SupplierPayment>(`${this.baseUrl}/${id}`, dto);
  }

  delete(id: number): Observable<void> {
    return this.http.delete<void>(`${this.baseUrl}/${id}`);
  }
}
