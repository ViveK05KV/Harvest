import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { MasterDataApiService } from '../../core/services/master-data-api.service';
import { SaveSupplierMaster, SupplierMaster } from '../../core/models/master-data.model';

@Injectable({ providedIn: 'root' })
export class SupplierMasterService extends MasterDataApiService<SupplierMaster, SaveSupplierMaster> {
  constructor(http: HttpClient) {
    super(http, 'suppliermaster');
  }
}
