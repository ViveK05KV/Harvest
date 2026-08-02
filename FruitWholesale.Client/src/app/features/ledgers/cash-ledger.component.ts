import { Component, OnInit, ViewChild, inject, signal } from '@angular/core';
import { CurrencyPipe, DatePipe } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { MatTableModule } from '@angular/material/table';
import { MatPaginator, MatPaginatorModule, PageEvent } from '@angular/material/paginator';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';
import { MatDatepickerModule } from '@angular/material/datepicker';
import { MatNativeDateModule } from '@angular/material/core';
import { MatProgressBarModule } from '@angular/material/progress-bar';
import { MatIconModule } from '@angular/material/icon';
import { MatButtonModule } from '@angular/material/button';
import { MatChipsModule } from '@angular/material/chips';
import { MatTooltipModule } from '@angular/material/tooltip';
import { LedgerService } from './ledger.service';
import { CASH_LEDGER_TRANSACTION_TYPES, CashLedgerEntry, cashLedgerTypeLabel } from '../../core/models/ledger.model';
import { PaginationRequest } from '../../core/models/common.model';
import { ExportService } from '../../core/services/export.service';
import { toIso } from '../../core/utils/date.util';

@Component({
  selector: 'app-cash-ledger',
  standalone: true,
  imports: [
    CurrencyPipe,
    DatePipe,
    FormsModule,
    MatTableModule,
    MatPaginatorModule,
    MatFormFieldModule,
    MatInputModule,
    MatSelectModule,
    MatDatepickerModule,
    MatNativeDateModule,
    MatProgressBarModule,
    MatIconModule,
    MatButtonModule,
    MatChipsModule,
    MatTooltipModule
  ],
  templateUrl: './cash-ledger.component.html'
})
export class CashLedgerComponent implements OnInit {
  private readonly ledgerService = inject(LedgerService);
  private readonly exportService = inject(ExportService);

  @ViewChild(MatPaginator) paginator!: MatPaginator;

  readonly displayedColumns = ['transactionDate', 'transactionType', 'paymentMode', 'narration', 'cashIn', 'cashOut', 'runningBalance'];
  readonly items = signal<CashLedgerEntry[]>([]);
  readonly totalCount = signal(0);
  readonly loading = signal(false);

  readonly transactionTypeOptions = CASH_LEDGER_TRANSACTION_TYPES;
  readonly typeLabel = cashLedgerTypeLabel;

  fromDate: Date | null = null;
  toDate: Date | null = null;
  transactionType: string | null = null;

  private readonly request: PaginationRequest = { pageNumber: 1, pageSize: 20 };

  ngOnInit(): void {
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
    this.ledgerService.getCashLedger(this.request, from, to, this.transactionType).subscribe({
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
