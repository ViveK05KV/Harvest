import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { MasterDataApiService } from '../../core/services/master-data-api.service';
import { ExpenseCategory, SaveExpenseCategory } from '../../core/models/master-data.model';

@Injectable({ providedIn: 'root' })
export class ExpenseCategoryService extends MasterDataApiService<ExpenseCategory, SaveExpenseCategory> {
  constructor(http: HttpClient) {
    super(http, 'expensecategory');
  }
}
