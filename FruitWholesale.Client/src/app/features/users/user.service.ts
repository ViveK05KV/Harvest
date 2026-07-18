import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { PaginatedList, PaginationRequest } from '../../core/models/common.model';
import { CreateUser, UpdateUser, User } from '../../core/models/master-data.model';
import { toHttpParams } from '../../core/utils/http-params.util';

@Injectable({ providedIn: 'root' })
export class UserService {
  private readonly baseUrl = `${environment.apiUrl}/users`;

  constructor(private readonly http: HttpClient) {}

  getPaged(request: PaginationRequest): Observable<PaginatedList<User>> {
    return this.http.get<PaginatedList<User>>(this.baseUrl, { params: toHttpParams({ ...request }) });
  }

  create(dto: CreateUser): Observable<User> {
    return this.http.post<User>(this.baseUrl, dto);
  }

  update(id: number, dto: UpdateUser): Observable<User> {
    return this.http.put<User>(`${this.baseUrl}/${id}`, dto);
  }

  activate(id: number): Observable<void> {
    return this.http.patch<void>(`${this.baseUrl}/${id}/activate`, {});
  }

  deactivate(id: number): Observable<void> {
    return this.http.patch<void>(`${this.baseUrl}/${id}/deactivate`, {});
  }
}
