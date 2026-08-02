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
import { SupplierPaymentService } from './supplier-payment.service';
import { SupplierPaymentFormComponent } from './supplier-payment-form.component';
import { SupplierMasterService } from '../supplier-master/supplier-master.service';
import { SupplierPayment } from '../../core/models/transactions.model';
import { SupplierMaster } from '../../core/models/master-data.model';
import { PaginationRequest } from '../../core/models/common.model';
import { NotificationService } from '../../core/services/notification.service';
import { ConfirmDialogService } from '../../shared/confirm-dialog/confirm-dialog.service';
import { toIso } from '../../core/utils/date.util';

@Component({
  selector: 'app-supplier-payment-list',
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
  templateUrl: './supplier-payment-list.component.html'
})
export class SupplierPaymentListComponent implements OnInit {
  private readonly service = inject(SupplierPaymentService);
  private readonly supplierService = inject(SupplierMasterService);
  private readonly dialog = inject(MatDialog);
  private readonly notification = inject(NotificationService);
  private readonly confirmDialog = inject(ConfirmDialogService);

  @ViewChild(MatPaginator) paginator!: MatPaginator;

  readonly displayedColumns = ['paymentDate', 'supplierName', 'amountPaid', 'discountAmount', 'paymentMode', 'actions'];
  readonly items = signal<SupplierPayment[]>([]);
  readonly totalCount = signal(0);
  readonly loading = signal(false);
  readonly suppliers = signal<SupplierMaster[]>([]);

  supplierId: number | null = null;
  fromDate: Date | null = null;
  toDate: Date | null = null;

  private readonly request: PaginationRequest = { pageNumber: 1, pageSize: 10 };

  ngOnInit(): void {
    this.supplierService.getAllActive().subscribe((suppliers) => this.suppliers.set(suppliers));
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
    this.service.getPaged(this.request, this.supplierId, from, to).subscribe({
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
      .open(SupplierPaymentFormComponent, { width: '480px', data: null })
      .afterClosed()
      .subscribe((result) => {
        if (!result) return;
        this.service.create(result).subscribe({
          next: () => {
            this.notification.success('Payment recorded. Supplier and Cash ledgers updated.');
            this.load();
          }
        });
      });
  }

  openEdit(item: SupplierPayment): void {
    this.dialog
      .open(SupplierPaymentFormComponent, { width: '480px', data: item })
      .afterClosed()
      .subscribe((result) => {
        if (!result) return;
        this.service.update(item.supplierPaymentID, result).subscribe({
          next: () => {
            this.notification.success('Payment updated. Ledgers recalculated.');
            this.load();
          }
        });
      });
  }

  deleteItem(item: SupplierPayment): void {
    this.confirmDialog
      .confirm({
        title: 'Delete Supplier Payment',
        message: `Delete this payment of ${item.amountPaid} to ${item.supplierName}? Ledgers will be reversed automatically.`,
        destructive: true,
        confirmLabel: 'Delete'
      })
      .subscribe((confirmed) => {
        if (!confirmed) return;
        this.service.delete(item.supplierPaymentID).subscribe({
          next: () => {
            this.notification.success('Payment deleted and ledgers updated.');
            this.load();
          }
        });
      });
  }
}
