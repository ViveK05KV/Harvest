import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { MasterDataApiService } from '../../core/services/master-data-api.service';
import { SaveSupplierMaster, SupplierBalanceAdjustment, SupplierMaster } from '../../core/models/master-data.model';

@Injectable({ providedIn: 'root' })
export class SupplierMasterService extends MasterDataApiService<SupplierMaster, SaveSupplierMaster> {
  constructor(http: HttpClient) {
    super(http, 'suppliermaster');
  }

  applyBalanceAdjustment(supplierId: number, dto: SupplierBalanceAdjustment): Observable<void> {
    return this.http.post<void>(`${this.baseUrl}/${supplierId}/balance-adjustment`, dto);
  }

  deleteAdjustment(supplierId: number, ledgerId: number): Observable<void> {
    return this.http.delete<void>(`${this.baseUrl}/${supplierId}/adjustment/${ledgerId}`);
  }
}
