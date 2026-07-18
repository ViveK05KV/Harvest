import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { MasterDataApiService } from '../../core/services/master-data-api.service';
import { SaveShopMaster, ShopMaster } from '../../core/models/master-data.model';

@Injectable({ providedIn: 'root' })
export class ShopMasterService extends MasterDataApiService<ShopMaster, SaveShopMaster> {
  constructor(http: HttpClient) {
    super(http, 'shopmaster');
  }
}
