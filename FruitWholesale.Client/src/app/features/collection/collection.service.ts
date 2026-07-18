import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { PaginatedList, PaginationRequest } from '../../core/models/common.model';
import { Collection, SaveCollection } from '../../core/models/transactions.model';
import { toHttpParams } from '../../core/utils/http-params.util';

@Injectable({ providedIn: 'root' })
export class CollectionService {
  private readonly baseUrl = `${environment.apiUrl}/collection`;

  constructor(private readonly http: HttpClient) {}

  getPaged(request: PaginationRequest, shopId?: number | null, fromDate?: string | null, toDate?: string | null) {
    return this.http.get<PaginatedList<Collection>>(this.baseUrl, {
      params: toHttpParams({ ...request, shopId, fromDate, toDate })
    });
  }

  create(dto: SaveCollection): Observable<Collection> {
    return this.http.post<Collection>(this.baseUrl, dto);
  }

  update(id: number, dto: SaveCollection): Observable<Collection> {
    return this.http.put<Collection>(`${this.baseUrl}/${id}`, dto);
  }

  delete(id: number): Observable<void> {
    return this.http.delete<void>(`${this.baseUrl}/${id}`);
  }
}
