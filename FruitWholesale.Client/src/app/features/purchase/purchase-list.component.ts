import { Component, OnInit, computed, inject, signal } from '@angular/core';
import { CurrencyPipe, DatePipe } from '@angular/common';
import { Router, RouterLink } from '@angular/router';
import { MatIconModule } from '@angular/material/icon';
import { MatMenuModule } from '@angular/material/menu';
import { MatProgressBarModule } from '@angular/material/progress-bar';
import { debounceTime, distinctUntilChanged, Subject } from 'rxjs';
import { PurchaseService } from './purchase.service';
import { SupplierMasterService } from '../supplier-master/supplier-master.service';
import { PurchaseListItem } from '../../core/models/transactions.model';
import { SupplierMaster } from '../../core/models/master-data.model';
import { PaginationRequest } from '../../core/models/common.model';
import { NotificationService } from '../../core/services/notification.service';
import { ConfirmDialogService } from '../../shared/confirm-dialog/confirm-dialog.service';
import { ExportService } from '../../core/services/export.service';

@Component({
  selector: 'app-purchase-list',
  standalone: true,
  imports: [CurrencyPipe, DatePipe, RouterLink, MatIconModule, MatMenuModule, MatProgressBarModule],
  templateUrl: './purchase-list.component.html',
  styleUrl: './purchase-list.component.scss'
})
export class PurchaseListComponent implements OnInit {
  private readonly service = inject(PurchaseService);
  private readonly supplierService = inject(SupplierMasterService);
  private readonly notification = inject(NotificationService);
  private readonly confirmDialog = inject(ConfirmDialogService);
  private readonly exportService = inject(ExportService);
  private readonly router = inject(Router);

  readonly items = signal<PurchaseListItem[]>([]);
  readonly totalCount = signal(0);
  readonly loading = signal(false);
  readonly suppliers = signal<SupplierMaster[]>([]);

  readonly pageIndex = signal(0);
  readonly pageSize = 10;

  searchTerm = '';
  supplierId: number | null = null;
  fromDate: string | null = null;
  toDate: string | null = null;

  private readonly request: PaginationRequest = { pageNumber: 1, pageSize: this.pageSize, searchTerm: '' };
  private readonly searchSubject = new Subject<string>();

  readonly rangeLabel = computed(() => {
    const total = this.totalCount();
    if (total === 0) return 'No invoices';
    const start = this.pageIndex() * this.pageSize + 1;
    const end = Math.min(start + this.pageSize - 1, total);
    return `${start}–${end} of ${total}`;
  });

  constructor() {
    this.searchSubject.pipe(debounceTime(350), distinctUntilChanged()).subscribe((term) => {
      this.request.searchTerm = term;
      this.request.pageNumber = 1;
      this.pageIndex.set(0);
      this.load();
    });
  }

  ngOnInit(): void {
    this.supplierService.getAllActive().subscribe((suppliers) => this.suppliers.set(suppliers));
    this.load();
  }

  onSearch(term: string): void {
    this.searchTerm = term;
    this.searchSubject.next(term);
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
    this.searchTerm = '';
    this.supplierId = null;
    this.fromDate = null;
    this.toDate = null;
    this.request.searchTerm = '';
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

  deletePurchase(item: PurchaseListItem): void {
    this.confirmDialog
      .confirm({
        title: 'Delete Purchase',
        message: `Delete invoice "${item.invoiceNo}"? This will reverse the supplier ledger entries automatically.`,
        destructive: true,
        confirmLabel: 'Delete'
      })
      .subscribe((confirmed) => {
        if (!confirmed) return;
        this.service.delete(item.purchaseID).subscribe({
          next: () => {
            this.notification.success('Purchase deleted and ledgers updated.');
            this.load();
          }
        });
      });
  }

  editPurchase(item: PurchaseListItem): void {
    this.router.navigate(['/purchase', item.purchaseID, 'edit']);
  }

  exportExcel(): void {
    this.exportService.exportToExcel(
      this.items(),
      [
        { header: 'Date', field: 'purchaseDate' },
        { header: 'Invoice No', field: 'invoiceNo' },
        { header: 'Supplier', field: 'supplierName' },
        { header: 'Amount', field: 'totalAmount' }
      ],
      'purchase'
    );
  }

  exportPdf(): void {
    this.exportService.exportToPdf(
      this.items(),
      [
        { header: 'Date', field: 'purchaseDate' },
        { header: 'Invoice No', field: 'invoiceNo' },
        { header: 'Supplier', field: 'supplierName' },
        { header: 'Amount', field: 'totalAmount' }
      ],
      'purchase',
      'Purchase Report'
    );
  }
}
