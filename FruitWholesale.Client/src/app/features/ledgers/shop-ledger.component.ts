import { Component, OnInit, computed, inject, signal } from '@angular/core';
import { CurrencyPipe, DatePipe } from '@angular/common';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressBarModule } from '@angular/material/progress-bar';
import { LedgerService } from './ledger.service';
import { ShopMasterService } from '../shop-master/shop-master.service';
import { ShopLedgerEntry, ledgerParticulars } from '../../core/models/ledger.model';
import { ShopMaster } from '../../core/models/master-data.model';
import { PaginationRequest } from '../../core/models/common.model';
import { ExportService } from '../../core/services/export.service';
import { NotificationService } from '../../core/services/notification.service';
import { ConfirmDialogService } from '../../shared/confirm-dialog/confirm-dialog.service';
import { toIso } from '../../core/utils/date.util';

@Component({
  selector: 'app-shop-ledger',
  standalone: true,
  imports: [CurrencyPipe, DatePipe, MatIconModule, MatProgressBarModule],
  templateUrl: './shop-ledger.component.html',
  styleUrl: './shop-ledger.component.scss'
})
export class ShopLedgerComponent implements OnInit {
  private readonly ledgerService = inject(LedgerService);
  private readonly shopService = inject(ShopMasterService);
  private readonly exportService = inject(ExportService);
  private readonly notification = inject(NotificationService);
  private readonly confirmDialog = inject(ConfirmDialogService);

  readonly particulars = ledgerParticulars;
  readonly shops = signal<ShopMaster[]>([]);
  readonly items = signal<ShopLedgerEntry[]>([]);
  readonly totalCount = signal(0);
  readonly loading = signal(false);

  readonly pageIndex = signal(0);
  readonly pageSize = 20;

  shopId: number | null = null;
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

  ngOnInit(): void {
    this.shopService.getAllActive().subscribe((shops) => {
      this.shops.set(shops);
      if (shops.length > 0) {
        this.shopId = shops[0].shopID;
        this.load();
      }
    });
  }

  readonly abs = Math.abs;

  selectedShop(): ShopMaster | undefined {
    return this.shops().find((s) => s.shopID === this.shopId);
  }

  isReceivable(netBalance: number): boolean {
    return netBalance >= 0;
  }

  isOpeningRow(row: ShopLedgerEntry, index: number): boolean {
    return this.pageIndex() === 0 && index === 0 && (row.transactionType === 'OpeningBalance' || row.transactionType === 'Adjustment');
  }

  netBalanceTooltip(shop: ShopMaster): string {
    return shop.linkedSupplierID
      ? `Combined position with linked Supplier: ${shop.linkedSupplierName}`
      : `${shop.shopName}'s outstanding balance`;
  }

  onShopChange(value: string): void {
    this.shopId = value ? Number(value) : null;
    this.onFilterChange();
  }

  onFilterChange(): void {
    if (!this.shopId) return;
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
    if (!this.shopId) return;
    this.loading.set(true);
    this.ledgerService.getShopLedger(this.shopId, this.request, this.fromDate, this.toDate).subscribe({
      next: (result) => {
        this.items.set(result.items);
        this.totalCount.set(result.totalCount);
        this.loading.set(false);
      },
      error: () => this.loading.set(false)
    });
  }

  deleteAdjustment(row: ShopLedgerEntry): void {
    if (!this.shopId) return;
    const shopId = this.shopId;
    this.confirmDialog
      .confirm({
        title: 'Delete Adjustment',
        message: `Delete this adjustment of ${row.debit || row.credit} dated ${new Date(row.transactionDate).toLocaleDateString()}? Balance will be recalculated.`,
        destructive: true,
        confirmLabel: 'Delete'
      })
      .subscribe((confirmed) => {
        if (!confirmed) return;
        this.shopService.deleteAdjustment(shopId, row.ledgerID).subscribe({
          next: () => {
            this.notification.success('Adjustment deleted and ledger recalculated.');
            this.load();
          }
        });
      });
  }

  exportExcel(): void {
    this.exportService.exportToExcel(
      this.items(),
      [
        { header: 'Date', field: 'transactionDate' },
        { header: 'Particulars', field: 'transactionType' },
        { header: 'Narration', field: 'narration' },
        { header: 'Sale', field: 'debit' },
        { header: 'Received', field: 'credit' },
        { header: 'Balance', field: 'runningBalance' }
      ],
      'shop-ledger'
    );
  }
}
