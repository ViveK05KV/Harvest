import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { MasterDataApiService } from '../../core/services/master-data-api.service';
import { FruitMaster, SaveFruitMaster } from '../../core/models/master-data.model';

@Injectable({ providedIn: 'root' })
export class FruitMasterService extends MasterDataApiService<FruitMaster, SaveFruitMaster> {
  constructor(http: HttpClient) {
    super(http, 'fruitmaster');
  }
}
