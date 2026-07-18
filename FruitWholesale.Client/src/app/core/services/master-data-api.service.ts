import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { PaginatedList, PaginationRequest } from '../models/common.model';
import { toHttpParams } from '../utils/http-params.util';

/**
 * Shared CRUD shape for the simple master-data entities (FruitMaster,
 * ShopMaster, SupplierMaster, ExpenseCategory) which all expose the same
 * paged-list / active-list / create / update / activate / deactivate
 * endpoints. Concrete services just supply the DTO types and endpoint name.
 */
export abstract class MasterDataApiService<TDto, TSaveDto> {
  protected constructor(protected readonly http: HttpClient, private readonly endpoint: string) {}

  private get baseUrl(): string {
    return `${environment.apiUrl}/${this.endpoint}`;
  }

  getPaged(request: PaginationRequest): Observable<PaginatedList<TDto>> {
    return this.http.get<PaginatedList<TDto>>(this.baseUrl, { params: toHttpParams({ ...request }) });
  }

  getAllActive(): Observable<TDto[]> {
    return this.http.get<TDto[]>(`${this.baseUrl}/active`);
  }

  getById(id: number): Observable<TDto> {
    return this.http.get<TDto>(`${this.baseUrl}/${id}`);
  }

  create(dto: TSaveDto): Observable<TDto> {
    return this.http.post<TDto>(this.baseUrl, dto);
  }

  update(id: number, dto: TSaveDto): Observable<TDto> {
    return this.http.put<TDto>(`${this.baseUrl}/${id}`, dto);
  }

  activate(id: number): Observable<void> {
    return this.http.patch<void>(`${this.baseUrl}/${id}/activate`, {});
  }

  deactivate(id: number): Observable<void> {
    return this.http.patch<void>(`${this.baseUrl}/${id}/deactivate`, {});
  }
}
