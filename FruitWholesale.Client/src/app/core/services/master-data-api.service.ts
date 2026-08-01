import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { shareReplay, tap } from 'rxjs/operators';
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

  protected get baseUrl(): string {
    return `${environment.apiUrl}/${this.endpoint}`;
  }

  // getAllActive() backs a lot of rarely-changing dropdown/lookup data (shops,
  // suppliers, fruits, routes, ...) that many forms/lists fetch independently
  // on every navigation. Cache it per service instance and invalidate on the
  // mutating calls below, instead of re-fetching from the network every time.
  private activeCache$: Observable<TDto[]> | null = null;

  getPaged(request: PaginationRequest): Observable<PaginatedList<TDto>> {
    return this.http.get<PaginatedList<TDto>>(this.baseUrl, { params: toHttpParams({ ...request }) });
  }

  getAllActive(): Observable<TDto[]> {
    this.activeCache$ ??= this.http.get<TDto[]>(`${this.baseUrl}/active`).pipe(shareReplay({ bufferSize: 1, refCount: false }));
    return this.activeCache$;
  }

  getById(id: number): Observable<TDto> {
    return this.http.get<TDto>(`${this.baseUrl}/${id}`);
  }

  create(dto: TSaveDto): Observable<TDto> {
    return this.http.post<TDto>(this.baseUrl, dto).pipe(tap(() => this.invalidateActiveCache()));
  }

  update(id: number, dto: TSaveDto): Observable<TDto> {
    return this.http.put<TDto>(`${this.baseUrl}/${id}`, dto).pipe(tap(() => this.invalidateActiveCache()));
  }

  activate(id: number): Observable<void> {
    return this.http.patch<void>(`${this.baseUrl}/${id}/activate`, {}).pipe(tap(() => this.invalidateActiveCache()));
  }

  deactivate(id: number): Observable<void> {
    return this.http.patch<void>(`${this.baseUrl}/${id}/deactivate`, {}).pipe(tap(() => this.invalidateActiveCache()));
  }

  private invalidateActiveCache(): void {
    this.activeCache$ = null;
  }
}
