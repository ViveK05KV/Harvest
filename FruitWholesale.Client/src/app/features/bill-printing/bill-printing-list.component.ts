import { Component, OnInit, ViewChild, inject, signal } from '@angular/core';
import { CurrencyPipe, DatePipe } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { MatTableModule } from '@angular/material/table';
import { MatPaginator, MatPaginatorModule, PageEvent } from '@angular/material/paginator';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatAutocompleteModule, MatAutocompleteSelectedEvent } from '@angular/material/autocomplete';
import { MatDatepickerModule } from '@angular/material/datepicker';
import { MatNativeDateModule } from '@angular/material/core';
import { MatTooltipModule } from '@angular/material/tooltip';
import { MatProgressBarModule } from '@angular/material/progress-bar';
import { MatDialog, MatDialogModule } from '@angular/material/dialog';
import { debounceTime, distinctUntilChanged, Subject } from 'rxjs';
import { SupplyService } from '../supply/supply.service';
import { ShopMasterService } from '../shop-master/shop-master.service';
import { SupplyListItem } from '../../core/models/transactions.model';
import { ShopMaster } from '../../core/models/master-data.model';
import { PaginationRequest } from '../../core/models/common.model';
import { toIso } from '../../core/utils/date.util';
import { BillPrintDialogComponent } from './bill-print-dialog.component';

@Component({
  selector: 'app-bill-printing-list',
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
    MatAutocompleteModule,
    MatDatepickerModule,
    MatNativeDateModule,
    MatTooltipModule,
    MatProgressBarModule,
    MatDialogModule
  ],
  templateUrl: './bill-printing-list.component.html'
})
export class BillPrintingListComponent implements OnInit {
  private readonly service = inject(SupplyService);
  private readonly shopService = inject(ShopMasterService);
  private readonly dialog = inject(MatDialog);

  @ViewChild(MatPaginator) paginator!: MatPaginator;

  readonly displayedColumns = ['supplyDate', 'invoiceNo', 'shopName', 'totalAmount', 'actions'];
  readonly items = signal<SupplyListItem[]>([]);
  readonly totalCount = signal(0);
  readonly loading = signal(false);
  readonly shops = signal<ShopMaster[]>([]);

  shopId: number | null = null;
  shopSearch = '';
  fromDate: Date | null = null;
  toDate: Date | null = null;

  private readonly request: PaginationRequest = { pageNumber: 1, pageSize: 10, searchTerm: '' };
  private readonly searchSubject = new Subject<string>();

  constructor() {
    this.searchSubject.pipe(debounceTime(350), distinctUntilChanged()).subscribe((term) => {
      this.request.searchTerm = term;
      this.request.pageNumber = 1;
      this.paginator.firstPage();
      this.load();
    });
  }

  ngOnInit(): void {
    this.shopService.getAllActive().subscribe((shops) => this.shops.set(shops));
    this.load();
  }

  onSearch(term: string): void {
    this.searchSubject.next(term);
  }

  onFilterChange(): void {
    this.request.pageNumber = 1;
    this.load();
  }

  filteredShops(search: string | null | undefined): ShopMaster[] {
    const term = (search ?? '').trim().toLowerCase();
    if (!term) return this.shops();
    return this.shops().filter((s) => s.shopName.toLowerCase().includes(term));
  }

  readonly displayShop = (value: unknown): string =>
    typeof value === 'number' ? (this.shops().find((s) => s.shopID === value)?.shopName ?? '') : typeof value === 'string' ? value : '';

  onShopFilterSelected(event: MatAutocompleteSelectedEvent): void {
    const shopId = event.option.value as number | null;
    this.shopId = shopId;
    this.shopSearch = shopId == null ? '' : (this.shops().find((s) => s.shopID === shopId)?.shopName ?? '');
    this.onFilterChange();
  }

  onShopSearchFocus(): void {
    if (this.shopSearch === (this.shops().find((s) => s.shopID === this.shopId)?.shopName ?? '')) this.shopSearch = '';
  }

  onShopSearchInput(): void {
    this.shopId = null;
    this.onFilterChange();
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
    this.service.getPaged(this.request, this.shopId, from, to).subscribe({
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
