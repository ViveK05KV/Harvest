import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import { MatTableModule } from '@angular/material/table';
import { MatPaginatorModule } from '@angular/material/paginator';
import { MatSortModule } from '@angular/material/sort';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSlideToggleModule } from '@angular/material/slide-toggle';
import { MatTooltipModule } from '@angular/material/tooltip';
import { MatProgressBarModule } from '@angular/material/progress-bar';
import { MasterListBase } from '../../core/base/master-list-base';
import { ExpenseCategoryService } from './expense-category.service';
import { ExpenseCategoryFormComponent } from './expense-category-form.component';
import { ExpenseCategory, SaveExpenseCategory } from '../../core/models/master-data.model';

@Component({
  selector: 'app-expense-category-list',
  standalone: true,
  imports: [
    MatTableModule,
    MatPaginatorModule,
    MatSortModule,
    MatButtonModule,
    MatIconModule,
    MatFormFieldModule,
    MatInputModule,
    MatSlideToggleModule,
    MatTooltipModule,
    MatProgressBarModule
  ],
  templateUrl: './expense-category-list.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class ExpenseCategoryListComponent extends MasterListBase<ExpenseCategory, SaveExpenseCategory> {
  readonly displayedColumns = ['categoryName', 'description', 'isActive', 'actions'];

  constructor() {
    super(inject(ExpenseCategoryService), {
      idOf: (c) => c.expenseCategoryID,
      nameOf: (c) => c.categoryName,
      isActiveOf: (c) => c.isActive,
      entityLabel: 'Category',
      createdMessage: 'Category added successfully.',
      updatedMessage: 'Category updated successfully.'
    });
  }

  openCreate(): void {
    this.openFormDialog(ExpenseCategoryFormComponent, '420px', null);
  }

  openEdit(category: ExpenseCategory): void {
    this.openFormDialog(ExpenseCategoryFormComponent, '420px', category);
  }
}
