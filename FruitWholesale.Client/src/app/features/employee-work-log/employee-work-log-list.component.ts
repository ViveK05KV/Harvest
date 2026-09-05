import { Component, OnInit, computed, inject, signal } from '@angular/core';
import { CurrencyPipe, DatePipe } from '@angular/common';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressBarModule } from '@angular/material/progress-bar';
import { MatDialog } from '@angular/material/dialog';
import { EmployeeWorkLogService } from './employee-work-log.service';
import { EmployeeWorkLogFormComponent } from './employee-work-log-form.component';
import { EmployeeLoanService } from './employee-loan.service';
import { EmployeeLoanRepaymentFormComponent } from './employee-loan-repayment-form.component';
import { EmployeeService } from '../employee/employee.service';
import { Employee, EmployeeLoanHistoryRow, EmployeeLoanSummaryRow, EmployeeWorkLog } from '../../core/models/master-data.model';
import { PaginationRequest } from '../../core/models/common.model';
import { NotificationService } from '../../core/services/notification.service';
import { ConfirmDialogService } from '../../shared/confirm-dialog/confirm-dialog.service';

@Component({
  selector: 'app-employee-work-log-list',
  standalone: true,
  imports: [CurrencyPipe, DatePipe, MatIconModule, MatProgressBarModule],
  templateUrl: './employee-work-log-list.component.html',
  styleUrl: './employee-work-log-list.component.scss'
})
export class EmployeeWorkLogListComponent implements OnInit {
  private readonly service = inject(EmployeeWorkLogService);
  private readonly loanService = inject(EmployeeLoanService);
  private readonly employeeService = inject(EmployeeService);
  private readonly dialog = inject(MatDialog);
  private readonly notification = inject(NotificationService);
  private readonly confirmDialog = inject(ConfirmDialogService);

  readonly activeTab = signal(0);

  readonly items = signal<EmployeeWorkLog[]>([]);
  readonly totalCount = signal(0);
  readonly loading = signal(false);
  readonly employees = signal<Employee[]>([]);

  readonly pageIndex = signal(0);
  readonly pageSize = 10;

  employeeId: number | null = null;
  fromDate: string | null = null;
  toDate: string | null = null;

  private readonly request: PaginationRequest = { pageNumber: 1, pageSize: this.pageSize };

  readonly rangeLabel = computed(() => {
    const total = this.totalCount();
    if (total === 0) return 'No entries';
    const start = this.pageIndex() * this.pageSize + 1;
    const end = Math.min(start + this.pageSize - 1, total);
    return `${start}–${end} of ${total}`;
  });

  // --- Loan Management tab ---
  readonly loanSummary = signal<EmployeeLoanSummaryRow[]>([]);
  readonly loanLoading = signal(false);
  readonly loanHistory = signal<EmployeeLoanHistoryRow[]>([]);
  readonly loanHistoryLoading = signal(false);
  selectedLoanEmployeeId: number | null = null;

  selectedLoanEmployee(): EmployeeLoanSummaryRow | undefined {
    return this.loanSummary().find((r) => r.employeeID === this.selectedLoanEmployeeId);
  }

  ngOnInit(): void {
    this.employeeService.getAllActive().subscribe((employees) => this.employees.set(employees));
    this.load();
  }

  onTabChange(index: number): void {
    this.activeTab.set(index);
    if (index === 1 && this.loanSummary().length === 0) this.loadLoanSummary();
  }

  loadLoanSummary(): void {
    this.loanLoading.set(true);
    this.loanService.getSummary().subscribe({
      next: (rows) => {
        const active = rows.filter((r) => r.outstandingLoan > 0);
        this.loanSummary.set(active);
        this.loanLoading.set(false);
        if (!this.selectedLoanEmployeeId && active.length > 0) this.selectLoanEmployee(active[0].employeeID);
      },
      error: () => this.loanLoading.set(false)
    });
  }

  selectLoanEmployee(employeeId: number): void {
    this.selectedLoanEmployeeId = employeeId;
    this.loadLoanHistory();
  }

  loadLoanHistory(): void {
    if (!this.selectedLoanEmployeeId) return;
    this.loanHistoryLoading.set(true);
    this.loanService.getHistory(this.selectedLoanEmployeeId).subscribe({
      next: (rows) => {
        this.loanHistory.set(rows);
        this.loanHistoryLoading.set(false);
      },
      error: () => this.loanHistoryLoading.set(false)
    });
  }

  openRecordRepayment(): void {
    const employee = this.selectedLoanEmployee();
    if (!employee) return;
    this.dialog
      .open(EmployeeLoanRepaymentFormComponent, {
        width: '480px',
        maxWidth: '95vw',
        data: { employeeId: employee.employeeID, employeeName: employee.employeeName, repayment: null },
        autoFocus: 'dialog'
      })
      .afterClosed()
      .subscribe((result) => {
        if (!result) return;
        this.loanService.createRepayment(result).subscribe({
          next: () => {
            this.notification.success('Repayment recorded. Cash ledger updated.');
            this.loadLoanSummary();
            this.loadLoanHistory();
          }
        });
      });
  }

  deleteRepayment(row: EmployeeLoanHistoryRow): void {
    if (!row.employeeLoanRepaymentID) return;
    const repaymentId = row.employeeLoanRepaymentID;
    this.confirmDialog
      .confirm({
        title: 'Delete Repayment',
        message: 'Delete this repayment? The cash ledger will be reversed automatically.',
        destructive: true,
        confirmLabel: 'Delete'
      })
      .subscribe((confirmed) => {
        if (!confirmed) return;
        this.loanService.deleteRepayment(repaymentId).subscribe({
          next: () => {
            this.notification.success('Repayment deleted and cash ledger updated.');
            this.loadLoanSummary();
            this.loadLoanHistory();
          }
        });
      });
  }

  onEmployeeChange(value: string): void {
    this.employeeId = value ? Number(value) : null;
    this.onFilterChange();
  }

  onFilterChange(): void {
    this.request.pageNumber = 1;
    this.pageIndex.set(0);
    this.load();
  }

  clearFilters(): void {
    this.employeeId = null;
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
    this.service.getPaged(this.request, this.employeeId, this.fromDate, this.toDate).subscribe({
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
      .open(EmployeeWorkLogFormComponent, { width: '520px', maxWidth: '95vw', data: null, autoFocus: 'dialog' })
      .afterClosed()
      .subscribe((result) => {
        if (!result) return;
        this.service.create(result).subscribe({
          next: () => {
            this.notification.success('Work entry recorded. Cash ledger updated.');
            this.load();
          }
        });
      });
  }

  openEdit(item: EmployeeWorkLog): void {
    this.dialog
      .open(EmployeeWorkLogFormComponent, { width: '520px', maxWidth: '95vw', data: item, autoFocus: 'dialog' })
      .afterClosed()
      .subscribe((result) => {
        if (!result) return;
        this.service.update(item.employeeWorkLogID, result).subscribe({
          next: () => {
            this.notification.success('Work entry updated. Ledgers recalculated.');
            this.load();
          }
        });
      });
  }

  deleteItem(item: EmployeeWorkLog): void {
    this.confirmDialog
      .confirm({
        title: 'Delete Work Entry',
        message: `Delete this ${item.jobType.toLowerCase()} entry for ${item.employeeName}? The cash ledger will be reversed automatically.`,
        destructive: true,
        confirmLabel: 'Delete'
      })
      .subscribe((confirmed) => {
        if (!confirmed) return;
        this.service.delete(item.employeeWorkLogID).subscribe({
          next: () => {
            this.notification.success('Work entry deleted and cash ledger updated.');
            this.load();
          }
        });
      });
  }
}
