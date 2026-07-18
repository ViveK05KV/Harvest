import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { MasterDataApiService } from '../../core/services/master-data-api.service';
import { Employee, SaveEmployee } from '../../core/models/master-data.model';

@Injectable({ providedIn: 'root' })
export class EmployeeService extends MasterDataApiService<Employee, SaveEmployee> {
  constructor(http: HttpClient) {
    super(http, 'employee');
  }
}
