import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { PaginatedList, PaginationRequest } from '../../core/models/common.model';
import { DailyExpense, SaveDailyExpense } from '../../core/models/transactions.model';
import { toHttpParams } from '../../core/utils/http-params.util';

@Injectable({ providedIn: 'root' })
export class DailyExpenseService {
  private readonly baseUrl = `${environment.apiUrl}/dailyexpense`;

  constructor(private readonly http: HttpClient) {}

  getPaged(request: PaginationRequest, expenseCategoryId?: number | null, fromDate?: string | null, toDate?: string | null) {
    return this.http.get<PaginatedList<DailyExpense>>(this.baseUrl, {
      params: toHttpParams({ ...request, expenseCategoryId, fromDate, toDate })
    });
  }

  create(dto: SaveDailyExpense): Observable<DailyExpense> {
    return this.http.post<DailyExpense>(this.baseUrl, dto);
  }

  update(id: number, dto: SaveDailyExpense): Observable<DailyExpense> {
    return this.http.put<DailyExpense>(`${this.baseUrl}/${id}`, dto);
  }

  delete(id: number): Observable<void> {
    return this.http.delete<void>(`${this.baseUrl}/${id}`);
  }
}
