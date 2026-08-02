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
import { EmployeeWorkLogService } from './employee-work-log.service';
import { EmployeeWorkLogFormComponent } from './employee-work-log-form.component';
import { EmployeeService } from '../employee/employee.service';
import { Employee, EmployeeWorkLog } from '../../core/models/master-data.model';
import { PaginationRequest } from '../../core/models/common.model';
import { NotificationService } from '../../core/services/notification.service';
import { ConfirmDialogService } from '../../shared/confirm-dialog/confirm-dialog.service';
import { toIso } from '../../core/utils/date.util';

@Component({
  selector: 'app-employee-work-log-list',
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
  templateUrl: './employee-work-log-list.component.html'
})
export class EmployeeWorkLogListComponent implements OnInit {
  private readonly service = inject(EmployeeWorkLogService);
  private readonly employeeService = inject(EmployeeService);
  private readonly dialog = inject(MatDialog);
  private readonly notification = inject(NotificationService);
  private readonly confirmDialog = inject(ConfirmDialogService);

  @ViewChild(MatPaginator) paginator!: MatPaginator;

  readonly displayedColumns = ['workDate', 'employeeName', 'jobType', 'routeName', 'amount', 'paymentMode', 'actions'];
  readonly items = signal<EmployeeWorkLog[]>([]);
  readonly totalCount = signal(0);
  readonly loading = signal(false);
  readonly employees = signal<Employee[]>([]);

  employeeId: number | null = null;
  fromDate: Date | null = null;
  toDate: Date | null = null;

  private readonly request: PaginationRequest = { pageNumber: 1, pageSize: 10 };

  ngOnInit(): void {
    this.employeeService.getAllActive().subscribe((employees) => this.employees.set(employees));
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
    this.service.getPaged(this.request, this.employeeId, from, to).subscribe({
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
      .open(EmployeeWorkLogFormComponent, { width: '480px', data: null })
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
      .open(EmployeeWorkLogFormComponent, { width: '480px', data: item })
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
