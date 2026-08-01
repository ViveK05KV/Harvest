import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { MasterDataApiService } from '../../core/services/master-data-api.service';
import { PaginatedList, PaginationRequest } from '../../core/models/common.model';
import { SaveShopMaster, ShopBalanceAdjustment, ShopMaster } from '../../core/models/master-data.model';
import { toHttpParams } from '../../core/utils/http-params.util';

@Injectable({ providedIn: 'root' })
export class ShopMasterService extends MasterDataApiService<ShopMaster, SaveShopMaster> {
  constructor(http: HttpClient) {
    super(http, 'shopmaster');
  }

  override getPaged(request: PaginationRequest, routeId?: number | null): Observable<PaginatedList<ShopMaster>> {
    return this.http.get<PaginatedList<ShopMaster>>(this.baseUrl, { params: toHttpParams({ ...request, routeId }) });
  }

  applyBalanceAdjustment(shopId: number, dto: ShopBalanceAdjustment): Observable<void> {
    return this.http.post<void>(`${this.baseUrl}/${shopId}/balance-adjustment`, dto);
  }
}
