import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressBarModule } from '@angular/material/progress-bar';
import { Sort } from '@angular/material/sort';
import { MasterListBase } from '../../core/base/master-list-base';
import { ExpenseCategoryService } from './expense-category.service';
import { ExpenseCategoryFormComponent } from './expense-category-form.component';
import { ExpenseCategory, SaveExpenseCategory } from '../../core/models/master-data.model';

@Component({
  selector: 'app-expense-category-list',
  standalone: true,
  imports: [MatIconModule, MatProgressBarModule],
  templateUrl: './expense-category-list.component.html',
  styleUrl: './expense-category-list.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class ExpenseCategoryListComponent extends MasterListBase<ExpenseCategory, SaveExpenseCategory> {
  private readonly expenseCategoryService = inject(ExpenseCategoryService);

  readonly sortDirection = signal<'asc' | 'desc' | ''>('');

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

  rangeLabel(): string {
    const total = this.totalCount();
    if (total === 0) return 'No categories';
    const start = (this.request.pageNumber - 1) * this.request.pageSize + 1;
    const end = Math.min(start + this.request.pageSize - 1, total);
    return `${start}–${end} of ${total}`;
  }

  prevPage(): void {
    if (this.request.pageNumber <= 1) return;
    this.request.pageNumber--;
    this.load();
  }

  nextPage(): void {
    if (this.request.pageNumber * this.request.pageSize >= this.totalCount()) return;
    this.request.pageNumber++;
    this.load();
  }

  toggleSort(): void {
    const next = this.sortDirection() === 'asc' ? 'desc' : this.sortDirection() === 'desc' ? '' : 'asc';
    this.sortDirection.set(next);
    this.onSort({ active: 'categoryName', direction: next } as Sort);
  }

  openCreate(): void {
    this.openFormDialog(ExpenseCategoryFormComponent, '460px', null);
  }

  openEdit(category: ExpenseCategory): void {
    this.openFormDialog(ExpenseCategoryFormComponent, '460px', category);
  }

  deleteCategory(category: ExpenseCategory): void {
    this.confirmDialog
      .confirm({
        title: 'Delete Category',
        message: `Delete "${category.categoryName}"? This can't be undone.`,
        destructive: true,
        confirmLabel: 'Delete'
      })
      .subscribe((confirmed) => {
        if (!confirmed) return;
        this.expenseCategoryService.delete(category.expenseCategoryID).subscribe({
          next: () => {
            this.notification.success('Category deleted.');
            this.load();
          }
        });
      });
  }
}
