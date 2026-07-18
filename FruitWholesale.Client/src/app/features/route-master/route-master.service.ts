import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { MasterDataApiService } from '../../core/services/master-data-api.service';
import { RouteMaster, SaveRouteMaster } from '../../core/models/master-data.model';

@Injectable({ providedIn: 'root' })
export class RouteMasterService extends MasterDataApiService<RouteMaster, SaveRouteMaster> {
  constructor(http: HttpClient) {
    super(http, 'routemaster');
  }
}
