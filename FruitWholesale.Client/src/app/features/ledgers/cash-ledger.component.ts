import { Component, OnInit, computed, inject, signal } from '@angular/core';
import { CurrencyPipe, DatePipe } from '@angular/common';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressBarModule } from '@angular/material/progress-bar';
import { LedgerService } from './ledger.service';
import { CASH_LEDGER_TRANSACTION_TYPES, CashLedgerEntry, cashLedgerTypeLabel } from '../../core/models/ledger.model';
import { PaginationRequest } from '../../core/models/common.model';
import { ExportService } from '../../core/services/export.service';

@Component({
  selector: 'app-cash-ledger',
  standalone: true,
  imports: [CurrencyPipe, DatePipe, MatIconModule, MatProgressBarModule],
  templateUrl: './cash-ledger.component.html',
  styleUrl: './cash-ledger.component.scss'
})
export class CashLedgerComponent implements OnInit {
  private readonly ledgerService = inject(LedgerService);
  private readonly exportService = inject(ExportService);

  readonly items = signal<CashLedgerEntry[]>([]);
  readonly totalCount = signal(0);
  readonly loading = signal(false);
  readonly currentBalance = signal<number | null>(null);

  readonly transactionTypeOptions = CASH_LEDGER_TRANSACTION_TYPES;
  readonly typeLabel = cashLedgerTypeLabel;

  readonly pageIndex = signal(0);
  readonly pageSize = 20;

  fromDate: string | null = null;
  toDate: string | null = null;
  transactionType: string | null = null;
  newestFirst = false;

  private readonly request: PaginationRequest = { pageNumber: 1, pageSize: this.pageSize };

  readonly rangeLabel = computed(() => {
    const total = this.totalCount();
    if (total === 0) return 'No entries';
    const start = this.pageIndex() * this.pageSize + 1;
    const end = Math.min(start + this.pageSize - 1, total);
    return `${start}–${end} of ${total}`;
  });

  ngOnInit(): void {
    this.load();
    this.ledgerService.getCurrentCashBalance().subscribe((balance) => this.currentBalance.set(balance));
  }

  onTypeChange(value: string): void {
    this.transactionType = value || null;
    this.onFilterChange();
  }

  onOrderChange(value: string): void {
    this.newestFirst = value === '1';
    this.request.pageNumber = 1;
    this.pageIndex.set(0);
    this.load();
  }

  onFilterChange(): void {
    this.request.pageNumber = 1;
    this.pageIndex.set(0);
    this.load();
  }

  clearFilters(): void {
    this.fromDate = null;
    this.toDate = null;
    this.transactionType = null;
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

  // The backend always pins the ledger's opening-balance-equivalent row (see
  // sp_RecalculateCashLedgerBalance) to the very first slot of the very first page,
  // regardless of sort direction. Only that specific row should get the highlight -
  // an ordinary later "Cash Adjustment" entry must not be styled the same way.
  isOpeningBalanceRow(row: CashLedgerEntry, index: number): boolean {
    return (
      this.pageIndex() === 0 &&
      index === 0 &&
      (row.transactionType === 'OpeningBalance' || row.transactionType === 'Adjustment')
    );
  }

  load(): void {
    this.loading.set(true);
    this.ledgerService.getCashLedger(this.request, this.fromDate, this.toDate, this.transactionType, this.newestFirst).subscribe({
      next: (result) => {
        this.items.set(result.items);
        this.totalCount.set(result.totalCount);
        this.loading.set(false);
      },
      error: () => this.loading.set(false)
    });
  }

  exportExcel(): void {
    this.exportService.exportToExcel(
      this.items(),
      [
        { header: 'Date', field: 'transactionDate' },
        { header: 'Type', field: 'transactionType' },
        { header: 'Mode', field: 'paymentMode' },
        { header: 'Narration', field: 'narration' },
        { header: 'Cash In', field: 'cashIn' },
        { header: 'Cash Out', field: 'cashOut' },
        { header: 'Balance', field: 'runningBalance' }
      ],
      'cash-ledger'
    );
  }
}
