import { Component, OnInit, ViewChild, inject, signal } from '@angular/core';
import { DatePipe } from '@angular/common';
import { MatDialogModule, MAT_DIALOG_DATA } from '@angular/material/dialog';
import { MatTableModule } from '@angular/material/table';
import { MatPaginator, MatPaginatorModule, PageEvent } from '@angular/material/paginator';
import { MatButtonModule } from '@angular/material/button';
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
  imports: [DatePipe, MatDialogModule, MatTableModule, MatPaginatorModule, MatButtonModule, MatProgressBarModule],
  templateUrl: './stock-ledger-dialog.component.html'
})
export class StockLedgerDialogComponent implements OnInit {
  private readonly stockService = inject(StockService);
  readonly data = inject<StockLedgerDialogData>(MAT_DIALOG_DATA);

  @ViewChild(MatPaginator) paginator!: MatPaginator;

  readonly displayedColumns = ['transactionDate', 'transactionType', 'narration', 'quantityIn', 'quantityOut', 'runningStock'];
  readonly items = signal<StockLedgerEntry[]>([]);
  readonly totalCount = signal(0);
  readonly loading = signal(false);

  private readonly request: PaginationRequest = { pageNumber: 1, pageSize: 10 };

  ngOnInit(): void {
    this.load();
  }

  onPage(event: PageEvent): void {
    this.request.pageNumber = event.pageIndex + 1;
    this.request.pageSize = event.pageSize;
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
}
