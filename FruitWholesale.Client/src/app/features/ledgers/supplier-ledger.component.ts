import { Component, OnInit, computed, inject, signal } from '@angular/core';
import { CurrencyPipe, DatePipe } from '@angular/common';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressBarModule } from '@angular/material/progress-bar';
import { LedgerService } from './ledger.service';
import { SupplierMasterService } from '../supplier-master/supplier-master.service';
import { SupplierLedgerEntry, ledgerParticulars } from '../../core/models/ledger.model';
import { SupplierMaster } from '../../core/models/master-data.model';
import { PaginationRequest } from '../../core/models/common.model';
import { ExportService } from '../../core/services/export.service';
import { NotificationService } from '../../core/services/notification.service';
import { ConfirmDialogService } from '../../shared/confirm-dialog/confirm-dialog.service';

type SupplierLedgerAmountColumn = 'purchase' | 'linkedShopSale' | 'supplierPayment' | 'linkedShopCollection' | 'other';

@Component({
  selector: 'app-supplier-ledger',
  standalone: true,
  imports: [CurrencyPipe, DatePipe, MatIconModule, MatProgressBarModule],
  templateUrl: './supplier-ledger.component.html',
  styleUrl: './supplier-ledger.component.scss'
})
export class SupplierLedgerComponent implements OnInit {
  private readonly ledgerService = inject(LedgerService);
  private readonly supplierService = inject(SupplierMasterService);
  private readonly exportService = inject(ExportService);
  private readonly notification = inject(NotificationService);
  private readonly confirmDialog = inject(ConfirmDialogService);

  readonly particulars = ledgerParticulars;
  readonly suppliers = signal<SupplierMaster[]>([]);
  readonly items = signal<SupplierLedgerEntry[]>([]);
  readonly totalCount = signal(0);
  readonly loading = signal(false);

  readonly pageIndex = signal(0);
  readonly pageSize = 20;

  supplierId: number | null = null;
  fromDate: string | null = null;
  toDate: string | null = null;
  newestFirst = true;

  private readonly request: PaginationRequest = { pageNumber: 1, pageSize: this.pageSize };

  readonly rangeLabel = computed(() => {
    const total = this.totalCount();
    if (total === 0) return 'No entries';
    const start = this.pageIndex() * this.pageSize + 1;
    const end = Math.min(start + this.pageSize - 1, total);
    return `${start}–${end} of ${total}`;
  });

  ngOnInit(): void {
    this.supplierService.getAllActive().subscribe((suppliers) => {
      this.suppliers.set(suppliers);
      if (suppliers.length > 0) {
        this.supplierId = suppliers[0].supplierID;
        this.load();
      }
    });
  }

  readonly abs = Math.abs;

  selectedSupplier(): SupplierMaster | undefined {
    return this.suppliers().find((s) => s.supplierID === this.supplierId);
  }

  isReceivable(netBalance: number): boolean {
    return netBalance >= 0;
  }

  isOpeningRow(row: SupplierLedgerEntry, index: number): boolean {
    return this.pageIndex() === 0 && index === 0 && (row.transactionType === 'OpeningBalance' || row.transactionType === 'Adjustment');
  }

  netBalanceTooltip(supplier: SupplierMaster): string {
    return supplier.linkedShopID
      ? `Combined position with linked Shop: ${supplier.linkedShopName}`
      : `Outstanding balance owed to ${supplier.supplierName}`;
  }

  amountFor(row: SupplierLedgerEntry, column: SupplierLedgerAmountColumn): number | null {
    switch (column) {
      case 'purchase':
        return row.transactionType === 'Purchase' && row.debit !== 0 ? row.debit : null;
      case 'linkedShopSale':
        return row.transactionType === 'LinkedShopSale' && row.credit !== 0 ? row.credit : null;
      case 'supplierPayment':
        return row.transactionType === 'SupplierPayment' && row.credit !== 0 ? row.credit : null;
      case 'linkedShopCollection':
        return row.transactionType === 'LinkedShopCollection' && row.debit !== 0 ? row.debit : null;
      case 'other': {
        const representedBalanceChange = row.transactionType === 'Purchase' || row.transactionType === 'LinkedShopCollection'
          ? row.debit
          : row.transactionType === 'LinkedShopSale' || row.transactionType === 'SupplierPayment'
            ? -row.credit
            : 0;
        const otherBalanceChange = row.debit - row.credit - representedBalanceChange;
        return otherBalanceChange === 0 ? null : otherBalanceChange;
      }
    }
  }

  onSupplierChange(value: string): void {
    this.supplierId = value ? Number(value) : null;
    this.onFilterChange();
  }

  onOrderChange(value: string): void {
    this.newestFirst = value === '1';
    this.onFilterChange();
  }

  onFilterChange(): void {
    if (!this.supplierId) return;
    this.request.pageNumber = 1;
    this.pageIndex.set(0);
    this.load();
  }

  clearFilters(): void {
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
    if (!this.supplierId) return;
    this.loading.set(true);
    this.ledgerService.getSupplierLedger(this.supplierId, this.request, this.fromDate, this.toDate, this.newestFirst).subscribe({
      next: (result) => {
        this.items.set(result.items);
        this.totalCount.set(result.totalCount);
        this.loading.set(false);
      },
      error: () => this.loading.set(false)
    });
  }

  deleteAdjustment(row: SupplierLedgerEntry): void {
    if (!this.supplierId) return;
    const supplierId = this.supplierId;
    this.confirmDialog
      .confirm({
        title: 'Delete Adjustment',
        message: `Delete this adjustment of ${row.debit || row.credit} dated ${new Date(row.transactionDate).toLocaleDateString()}? Balance will be recalculated.`,
        destructive: true,
        confirmLabel: 'Delete'
      })
      .subscribe((confirmed) => {
        if (!confirmed) return;
        this.supplierService.deleteAdjustment(supplierId, row.ledgerID).subscribe({
          next: () => {
            this.notification.success('Adjustment deleted and ledger recalculated.');
            this.load();
          }
        });
      });
  }

  exportExcel(): void {
    const rows = this.items().map((row) => ({
      transactionDate: row.transactionDate,
      particulars: this.particulars(row.transactionType),
      transactionType: row.transactionType,
      narration: row.narration,
      purchase: this.amountFor(row, 'purchase'),
      linkedShopSale: this.amountFor(row, 'linkedShopSale'),
      supplierPayment: this.amountFor(row, 'supplierPayment'),
      linkedShopCollection: this.amountFor(row, 'linkedShopCollection'),
      other: this.amountFor(row, 'other'),
      runningBalance: row.runningBalance
    }));

    this.exportService.exportToExcel(
      rows,
      [
        { header: 'Date', field: 'transactionDate' },
        { header: 'Particulars', field: 'particulars' },
        { header: 'Transaction type', field: 'transactionType' },
        { header: 'Narration', field: 'narration' },
        { header: 'Purchase', field: 'purchase' },
        { header: 'Sale to linked shop', field: 'linkedShopSale' },
        { header: 'Payment', field: 'supplierPayment' },
        { header: 'Collection from linked shop', field: 'linkedShopCollection' },
        { header: 'Other (Dr − Cr)', field: 'other' },
        { header: 'Balance', field: 'runningBalance' }
      ],
      'supplier-ledger'
    );
  }
}
