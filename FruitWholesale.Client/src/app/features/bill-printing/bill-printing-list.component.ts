import { Component, OnInit, computed, inject, signal } from '@angular/core';
import { CurrencyPipe, DatePipe } from '@angular/common';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressBarModule } from '@angular/material/progress-bar';
import { MatDialog } from '@angular/material/dialog';
import { debounceTime, distinctUntilChanged, Subject } from 'rxjs';
import { SupplyService } from '../supply/supply.service';
import { ShopMasterService } from '../shop-master/shop-master.service';
import { SupplyListItem } from '../../core/models/transactions.model';
import { ShopMaster } from '../../core/models/master-data.model';
import { PaginationRequest } from '../../core/models/common.model';
import { BillPrintDialogComponent } from './bill-print-dialog.component';

@Component({
  selector: 'app-bill-printing-list',
  standalone: true,
  imports: [CurrencyPipe, DatePipe, MatIconModule, MatProgressBarModule],
  templateUrl: './bill-printing-list.component.html',
  styleUrl: './bill-printing-list.component.scss'
})
export class BillPrintingListComponent implements OnInit {
  private readonly service = inject(SupplyService);
  private readonly shopService = inject(ShopMasterService);
  private readonly dialog = inject(MatDialog);

  readonly items = signal<SupplyListItem[]>([]);
  readonly totalCount = signal(0);
  readonly loading = signal(false);
  readonly shops = signal<ShopMaster[]>([]);

  readonly pageIndex = signal(0);
  readonly pageSize = 10;

  searchTerm = '';
  shopId: number | null = null;
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
    this.shopService.getAllActive().subscribe((shops) => this.shops.set(shops));
    this.load();
  }

  onSearch(term: string): void {
    this.searchTerm = term;
    this.searchSubject.next(term);
  }

  onShopChange(value: string): void {
    this.shopId = value ? Number(value) : null;
    this.onFilterChange();
  }

  onFilterChange(): void {
    this.request.pageNumber = 1;
    this.pageIndex.set(0);
    this.load();
  }

  clearFilters(): void {
    this.searchTerm = '';
    this.shopId = null;
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
    this.service.getPaged(this.request, this.shopId, this.fromDate, this.toDate).subscribe({
      next: (result) => {
        this.items.set(result.items);
        this.totalCount.set(result.totalCount);
        this.loading.set(false);
      },
      error: () => this.loading.set(false)
    });
  }

  printBill(item: SupplyListItem): void {
    this.dialog.open(BillPrintDialogComponent, {
      data: { supplyId: item.supplyID },
      width: '420px',
      maxHeight: '90vh',
      panelClass: 'bill-print-dialog-panel'
    });
  }
}
