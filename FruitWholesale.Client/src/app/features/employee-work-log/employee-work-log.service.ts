import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { PaginatedList, PaginationRequest } from '../../core/models/common.model';
import { EmployeeWorkLog, SaveEmployeeWorkLog } from '../../core/models/master-data.model';
import { toHttpParams } from '../../core/utils/http-params.util';

@Injectable({ providedIn: 'root' })
export class EmployeeWorkLogService {
  private readonly baseUrl = `${environment.apiUrl}/employeeworklog`;

  constructor(private readonly http: HttpClient) {}

  getPaged(request: PaginationRequest, employeeId?: number | null, fromDate?: string | null, toDate?: string | null) {
    return this.http.get<PaginatedList<EmployeeWorkLog>>(this.baseUrl, {
      params: toHttpParams({ ...request, employeeId, fromDate, toDate })
    });
  }

  create(dto: SaveEmployeeWorkLog): Observable<EmployeeWorkLog> {
    return this.http.post<EmployeeWorkLog>(this.baseUrl, dto);
  }

  update(id: number, dto: SaveEmployeeWorkLog): Observable<EmployeeWorkLog> {
    return this.http.put<EmployeeWorkLog>(`${this.baseUrl}/${id}`, dto);
  }

  delete(id: number): Observable<void> {
    return this.http.delete<void>(`${this.baseUrl}/${id}`);
  }
}
