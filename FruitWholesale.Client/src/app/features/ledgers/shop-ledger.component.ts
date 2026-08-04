import { Component, OnInit, ViewChild, inject, signal } from '@angular/core';
import { CurrencyPipe, DatePipe } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { MatTableModule } from '@angular/material/table';
import { MatPaginator, MatPaginatorModule, PageEvent } from '@angular/material/paginator';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';
import { MatAutocompleteModule, MatAutocompleteSelectedEvent } from '@angular/material/autocomplete';
import { MatDatepickerModule } from '@angular/material/datepicker';
import { MatNativeDateModule } from '@angular/material/core';
import { MatProgressBarModule } from '@angular/material/progress-bar';
import { MatIconModule } from '@angular/material/icon';
import { MatButtonModule } from '@angular/material/button';
import { MatMenuModule } from '@angular/material/menu';
import { MatTooltipModule } from '@angular/material/tooltip';
import { LedgerService } from './ledger.service';
import { ShopMasterService } from '../shop-master/shop-master.service';
import { ShopLedgerEntry, ledgerParticulars } from '../../core/models/ledger.model';
import { ShopMaster } from '../../core/models/master-data.model';
import { PaginationRequest } from '../../core/models/common.model';
import { ExportService } from '../../core/services/export.service';
import { toIso } from '../../core/utils/date.util';

@Component({
  selector: 'app-shop-ledger',
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
    MatAutocompleteModule,
    MatDatepickerModule,
    MatNativeDateModule,
    MatProgressBarModule,
    MatIconModule,
    MatButtonModule,
    MatMenuModule,
    MatTooltipModule
  ],
  templateUrl: './shop-ledger.component.html'
})
export class ShopLedgerComponent implements OnInit {
  private readonly ledgerService = inject(LedgerService);
  private readonly shopService = inject(ShopMasterService);
  private readonly exportService = inject(ExportService);

  @ViewChild(MatPaginator) paginator!: MatPaginator;

  readonly displayedColumns = ['transactionDate', 'particulars', 'sale', 'received', 'runningBalance'];
  readonly particulars = ledgerParticulars;
  readonly shops = signal<ShopMaster[]>([]);
  readonly items = signal<ShopLedgerEntry[]>([]);
  readonly totalCount = signal(0);
  readonly loading = signal(false);

  shopId: number | null = null;
  shopSearch = '';
  fromDate: Date | null = null;
  toDate: Date | null = null;

  private readonly request: PaginationRequest = { pageNumber: 1, pageSize: 20 };

  ngOnInit(): void {
    this.shopService.getAllActive().subscribe((shops) => {
      this.shops.set(shops);
      if (shops.length > 0) {
        this.shopId = shops[0].shopID;
        this.shopSearch = shops[0].shopName;
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

  netBalanceTooltip(shop: ShopMaster): string {
    return shop.linkedSupplierID
      ? `Combined position with linked Supplier: ${shop.linkedSupplierName}`
      : `${shop.shopName}'s outstanding balance`;
  }

  onFilterChange(): void {
    if (!this.shopId) return;
    this.request.pageNumber = 1;
    this.load();
  }

  filteredShops(search: string | null | undefined): ShopMaster[] {
    const term = (search ?? '').trim().toLowerCase();
    if (!term) return this.shops();
    return this.shops().filter((s) => s.shopName.toLowerCase().includes(term));
  }

  onShopFilterSelected(event: MatAutocompleteSelectedEvent): void {
    const shopId = event.option.value as number | null;
    this.shopId = shopId;
    this.shopSearch = shopId == null ? '' : (this.shops().find((s) => s.shopID === shopId)?.shopName ?? '');
    this.onFilterChange();
  }

  // The field always displays the currently selected shop's name. Clicking the
  // dropdown arrow (or focusing/clicking the text directly) clears it so the panel
  // opens showing the full list to browse or type-filter, instead of being
  // narrowed down to just the already-selected name. Only clears when the field
  // is showing that settled name (not a query the user is still mid-typing), so
  // clicking to reposition the cursor while typing doesn't wipe it out - and
  // fires on both focus and click since the field stays focused after a
  // selection, so a second click there wouldn't otherwise re-trigger (focus).
  onShopSearchFocus(): void {
    if (this.shopSearch !== (this.selectedShop()?.shopName ?? '')) return;
    this.shopSearch = '';
  }

  onShopSearchBlur(): void {
    if (this.shopSearch) return;
    this.shopSearch = this.selectedShop()?.shopName ?? '';
  }

  // The dropdown arrow always shows the full list, regardless of whatever partial
  // query might currently be mid-typed - unlike onShopSearchFocus, which leaves an
  // in-progress query alone.
  showAllShops(): void {
    this.shopSearch = '';
  }

  onPage(event: PageEvent): void {
    this.request.pageNumber = event.pageIndex + 1;
    this.request.pageSize = event.pageSize;
    this.load();
  }

  load(): void {
    if (!this.shopId) return;
    this.loading.set(true);
    const from = this.fromDate ? toIso(this.fromDate) : null;
    const to = this.toDate ? toIso(this.toDate) : null;
    this.ledgerService.getShopLedger(this.shopId, this.request, from, to).subscribe({
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
