import { Component, OnInit, computed, inject, signal } from '@angular/core';
import { CurrencyPipe, DatePipe } from '@angular/common';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressBarModule } from '@angular/material/progress-bar';
import { MatDialog } from '@angular/material/dialog';
import { DailyExpenseService } from './daily-expense.service';
import { DailyExpenseFormComponent } from './daily-expense-form.component';
import { ExpenseCategoryService } from '../expense-category/expense-category.service';
import { DailyExpense } from '../../core/models/transactions.model';
import { ExpenseCategory } from '../../core/models/master-data.model';
import { PaginationRequest } from '../../core/models/common.model';
import { NotificationService } from '../../core/services/notification.service';
import { ConfirmDialogService } from '../../shared/confirm-dialog/confirm-dialog.service';

@Component({
  selector: 'app-daily-expense-list',
  standalone: true,
  imports: [CurrencyPipe, DatePipe, MatIconModule, MatProgressBarModule],
  templateUrl: './daily-expense-list.component.html',
  styleUrl: './daily-expense-list.component.scss'
})
export class DailyExpenseListComponent implements OnInit {
  private readonly service = inject(DailyExpenseService);
  private readonly categoryService = inject(ExpenseCategoryService);
  private readonly dialog = inject(MatDialog);
  private readonly notification = inject(NotificationService);
  private readonly confirmDialog = inject(ConfirmDialogService);

  readonly items = signal<DailyExpense[]>([]);
  readonly totalCount = signal(0);
  readonly loading = signal(false);
  readonly categories = signal<ExpenseCategory[]>([]);

  readonly pageIndex = signal(0);
  readonly pageSize = 10;

  categoryId: number | null = null;
  fromDate: string | null = null;
  toDate: string | null = null;

  private readonly request: PaginationRequest = { pageNumber: 1, pageSize: this.pageSize };

  readonly rangeLabel = computed(() => {
    const total = this.totalCount();
    if (total === 0) return 'No expenses';
    const start = this.pageIndex() * this.pageSize + 1;
    const end = Math.min(start + this.pageSize - 1, total);
    return `${start}–${end} of ${total}`;
  });

  ngOnInit(): void {
    this.categoryService.getAllActive().subscribe((categories) => this.categories.set(categories));
    this.load();
  }

  onCategoryChange(value: string): void {
    this.categoryId = value ? Number(value) : null;
    this.onFilterChange();
  }

  onFilterChange(): void {
    this.request.pageNumber = 1;
    this.pageIndex.set(0);
    this.load();
  }

  clearFilters(): void {
    this.categoryId = null;
    this.fromDate = null;
    this.toDate = null;
    this.onFilterChange();
  }

  prevPage(): void {
    if (this.pageIndex() === 0) return;
    this.pageIndex.update((i) => i - 1);
    this.request.pageNumber = this.pageIndex() + 1;
    this.load();
  }

  nextPage(): void {
    if ((this.pageIndex() + 1) * this.pageSize >= this.totalCount()) return;
    this.pageIndex.update((i) => i + 1);
    this.request.pageNumber = this.pageIndex() + 1;
    this.load();
  }

  load(): void {
    this.loading.set(true);
    this.service.getPaged(this.request, this.categoryId, this.fromDate, this.toDate).subscribe({
      next: (result) => {
        this.items.set(result.items);
        this.totalCount.set(result.totalCount);
        this.loading.set(false);
      },
      error: () => this.loading.set(false)
    });
  }

  openCreate(): void {
    this.dialog
      .open(DailyExpenseFormComponent, { width: '520px', maxWidth: '95vw', data: null, autoFocus: 'dialog' })
      .afterClosed()
      .subscribe((result) => {
        if (!result) return;
        this.service.create(result).subscribe({
          next: () => {
            this.notification.success('Expense recorded. Cash ledger updated.');
            this.load();
          }
        });
      });
  }

  openEdit(item: DailyExpense): void {
    this.dialog
      .open(DailyExpenseFormComponent, { width: '520px', maxWidth: '95vw', data: item, autoFocus: 'dialog' })
      .afterClosed()
      .subscribe((result) => {
        if (!result) return;
        this.service.update(item.expenseID, result).subscribe({
          next: () => {
            this.notification.success('Expense updated. Cash ledger recalculated.');
            this.load();
          }
        });
      });
  }

  deleteItem(item: DailyExpense): void {
    this.confirmDialog
      .confirm({
        title: 'Delete Expense',
        message: `Delete this expense of ${item.amount}? The cash ledger will be reversed automatically.`,
        destructive: true,
        confirmLabel: 'Delete'
      })
      .subscribe((confirmed) => {
        if (!confirmed) return;
        this.service.delete(item.expenseID).subscribe({
          next: () => {
            this.notification.success('Expense deleted and cash ledger updated.');
            this.load();
          }
        });
      });
  }
}
