import { Component, OnInit, ViewChild, inject, signal } from '@angular/core';
import { CurrencyPipe, DatePipe } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { MatTableModule } from '@angular/material/table';
import { MatPaginator, MatPaginatorModule, PageEvent } from '@angular/material/paginator';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';
import { MatChipsModule } from '@angular/material/chips';
import { MatTooltipModule } from '@angular/material/tooltip';
import { MatProgressBarModule } from '@angular/material/progress-bar';
import { MatDatepickerModule } from '@angular/material/datepicker';
import { MatNativeDateModule } from '@angular/material/core';
import { MatDialog } from '@angular/material/dialog';
import { DailyExpenseService } from './daily-expense.service';
import { DailyExpenseFormComponent } from './daily-expense-form.component';
import { ExpenseCategoryService } from '../expense-category/expense-category.service';
import { DailyExpense } from '../../core/models/transactions.model';
import { ExpenseCategory } from '../../core/models/master-data.model';
import { PaginationRequest } from '../../core/models/common.model';
import { NotificationService } from '../../core/services/notification.service';
import { ConfirmDialogService } from '../../shared/confirm-dialog/confirm-dialog.service';
import { toIso } from '../../core/utils/date.util';

@Component({
  selector: 'app-daily-expense-list',
  standalone: true,
  imports: [
    CurrencyPipe,
    DatePipe,
    FormsModule,
    MatTableModule,
    MatPaginatorModule,
    MatButtonModule,
    MatIconModule,
    MatFormFieldModule,
    MatInputModule,
    MatSelectModule,
    MatChipsModule,
    MatTooltipModule,
    MatProgressBarModule,
    MatDatepickerModule,
    MatNativeDateModule
  ],
  templateUrl: './daily-expense-list.component.html'
})
export class DailyExpenseListComponent implements OnInit {
  private readonly service = inject(DailyExpenseService);
  private readonly categoryService = inject(ExpenseCategoryService);
  private readonly dialog = inject(MatDialog);
  private readonly notification = inject(NotificationService);
  private readonly confirmDialog = inject(ConfirmDialogService);

  @ViewChild(MatPaginator) paginator!: MatPaginator;

  readonly displayedColumns = ['expenseDate', 'categoryName', 'paidTo', 'amount', 'paymentMode', 'actions'];
  readonly items = signal<DailyExpense[]>([]);
  readonly totalCount = signal(0);
  readonly loading = signal(false);
  readonly categories = signal<ExpenseCategory[]>([]);

  categoryId: number | null = null;
  fromDate: Date | null = null;
  toDate: Date | null = null;

  private readonly request: PaginationRequest = { pageNumber: 1, pageSize: 10 };

  ngOnInit(): void {
    this.categoryService.getAllActive().subscribe((categories) => this.categories.set(categories));
    this.load();
  }

  onFilterChange(): void {
    this.request.pageNumber = 1;
    this.load();
  }

  onPage(event: PageEvent): void {
    this.request.pageNumber = event.pageIndex + 1;
    this.request.pageSize = event.pageSize;
    this.load();
  }

  load(): void {
    this.loading.set(true);
    const from = this.fromDate ? toIso(this.fromDate) : null;
    const to = this.toDate ? toIso(this.toDate) : null;
    this.service.getPaged(this.request, this.categoryId, from, to).subscribe({
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
      .open(DailyExpenseFormComponent, { width: '480px', data: null })
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
      .open(DailyExpenseFormComponent, { width: '480px', data: item })
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
