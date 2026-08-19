import { Component, OnInit, computed, inject, signal } from '@angular/core';
import { CurrencyPipe, DatePipe } from '@angular/common';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressBarModule } from '@angular/material/progress-bar';
import { MatDialog } from '@angular/material/dialog';
import { SupplierPaymentService } from './supplier-payment.service';
import { SupplierPaymentFormComponent } from './supplier-payment-form.component';
import { SupplierMasterService } from '../supplier-master/supplier-master.service';
import { SupplierPayment } from '../../core/models/transactions.model';
import { SupplierMaster } from '../../core/models/master-data.model';
import { PaginationRequest } from '../../core/models/common.model';
import { NotificationService } from '../../core/services/notification.service';
import { ConfirmDialogService } from '../../shared/confirm-dialog/confirm-dialog.service';

@Component({
  selector: 'app-supplier-payment-list',
  standalone: true,
  imports: [CurrencyPipe, DatePipe, MatIconModule, MatProgressBarModule],
  templateUrl: './supplier-payment-list.component.html',
  styleUrl: './supplier-payment-list.component.scss'
})
export class SupplierPaymentListComponent implements OnInit {
  private readonly service = inject(SupplierPaymentService);
  private readonly supplierService = inject(SupplierMasterService);
  private readonly dialog = inject(MatDialog);
  private readonly notification = inject(NotificationService);
  private readonly confirmDialog = inject(ConfirmDialogService);

  readonly items = signal<SupplierPayment[]>([]);
  readonly totalCount = signal(0);
  readonly loading = signal(false);
  readonly suppliers = signal<SupplierMaster[]>([]);

  readonly pageIndex = signal(0);
  readonly pageSize = 10;

  supplierId: number | null = null;
  fromDate: string | null = null;
  toDate: string | null = null;

  private readonly request: PaginationRequest = { pageNumber: 1, pageSize: this.pageSize };

  readonly rangeLabel = computed(() => {
    const total = this.totalCount();
    if (total === 0) return 'No payments';
    const start = this.pageIndex() * this.pageSize + 1;
    const end = Math.min(start + this.pageSize - 1, total);
    return `${start}–${end} of ${total}`;
  });

  ngOnInit(): void {
    this.supplierService.getAllActive().subscribe((suppliers) => this.suppliers.set(suppliers));
    this.load();
  }

  onSupplierChange(value: string): void {
    this.supplierId = value ? Number(value) : null;
    this.onFilterChange();
  }

  onFilterChange(): void {
    this.request.pageNumber = 1;
    this.pageIndex.set(0);
    this.load();
  }

  clearFilters(): void {
    this.supplierId = null;
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
    this.service.getPaged(this.request, this.supplierId, this.fromDate, this.toDate).subscribe({
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
      .open(SupplierPaymentFormComponent, { width: '900px', maxWidth: '95vw', data: null, autoFocus: 'dialog' })
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
      .open(SupplierPaymentFormComponent, { width: '900px', maxWidth: '95vw', data: item, autoFocus: 'dialog' })
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
