import { Component, OnInit, computed, inject, signal } from '@angular/core';
import { DatePipe } from '@angular/common';
import { MatDialogModule, MAT_DIALOG_DATA, MatDialogRef } from '@angular/material/dialog';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressBarModule } from '@angular/material/progress-bar';
import { StockService } from './stock.service';
import { StockLedgerEntry } from '../../core/models/stock.model';
import { PaginationRequest } from '../../core/models/common.model';

export interface StockLedgerDialogData {
  fruitID: number;
  fruitName: string;
  unit: string;
}

@Component({
  selector: 'app-stock-ledger-dialog',
  standalone: true,
  imports: [DatePipe, MatDialogModule, MatIconModule, MatProgressBarModule],
  templateUrl: './stock-ledger-dialog.component.html',
  styleUrl: './stock-ledger-dialog.component.scss'
})
export class StockLedgerDialogComponent implements OnInit {
  private readonly stockService = inject(StockService);
  private readonly dialogRef = inject(MatDialogRef<StockLedgerDialogComponent>);
  readonly data = inject<StockLedgerDialogData>(MAT_DIALOG_DATA);

  readonly items = signal<StockLedgerEntry[]>([]);
  readonly totalCount = signal(0);
  readonly loading = signal(false);

  readonly pageIndex = signal(0);
  readonly pageSize = 10;

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
    this.stockService.getStockLedger(this.data.fruitID, this.request).subscribe({
      next: (result) => {
        this.items.set(result.items);
        this.totalCount.set(result.totalCount);
        this.loading.set(false);
      },
      error: () => this.loading.set(false)
    });
  }

  close(): void {
    this.dialogRef.close();
  }
}
