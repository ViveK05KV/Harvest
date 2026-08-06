import { Component, OnInit, ViewChild, inject, signal } from '@angular/core';
import { CurrencyPipe, DatePipe } from '@angular/common';
import { Router, RouterLink } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { MatTableModule } from '@angular/material/table';
import { MatPaginator, MatPaginatorModule, PageEvent } from '@angular/material/paginator';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';
import { MatAutocompleteModule, MatAutocompleteSelectedEvent } from '@angular/material/autocomplete';
import { MatDatepickerModule } from '@angular/material/datepicker';
import { MatNativeDateModule } from '@angular/material/core';
import { MatTooltipModule } from '@angular/material/tooltip';
import { MatProgressBarModule } from '@angular/material/progress-bar';
import { MatMenuModule } from '@angular/material/menu';
import { debounceTime, distinctUntilChanged, Subject } from 'rxjs';
import { SupplyService } from './supply.service';
import { ShopMasterService } from '../shop-master/shop-master.service';
import { SupplyListItem } from '../../core/models/transactions.model';
import { ShopMaster } from '../../core/models/master-data.model';
import { PaginationRequest } from '../../core/models/common.model';
import { NotificationService } from '../../core/services/notification.service';
import { ConfirmDialogService } from '../../shared/confirm-dialog/confirm-dialog.service';
import { ExportService } from '../../core/services/export.service';
import { toIso } from '../../core/utils/date.util';

@Component({
  selector: 'app-supply-list',
  standalone: true,
  imports: [
    CurrencyPipe,
    DatePipe,
    FormsModule,
    RouterLink,
    MatTableModule,
    MatPaginatorModule,
    MatButtonModule,
    MatIconModule,
    MatFormFieldModule,
    MatInputModule,
    MatSelectModule,
    MatAutocompleteModule,
    MatDatepickerModule,
    MatNativeDateModule,
    MatTooltipModule,
    MatProgressBarModule,
    MatMenuModule
  ],
  templateUrl: './supply-list.component.html'
})
export class SupplyListComponent implements OnInit {
  private readonly service = inject(SupplyService);
  private readonly shopService = inject(ShopMasterService);
  private readonly notification = inject(NotificationService);
  private readonly confirmDialog = inject(ConfirmDialogService);
  private readonly exportService = inject(ExportService);
  private readonly router = inject(Router);

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

  onShopFilterSelected(event: MatAutocompleteSelectedEvent): void {
    const shopId = event.option.value as number | null;
    this.shopId = shopId;
    this.shopSearch = shopId == null ? '' : (this.shops().find((s) => s.shopID === shopId)?.shopName ?? '');
    this.onFilterChange();
  }

  onShopSearchFocus(): void {
    if (this.shopSearch === (this.shops().find((s) => s.shopID === this.shopId)?.shopName ?? '')) this.shopSearch = '';
  }

  // Typing away from the settled shop name must clear the stale filter and
  // reload - otherwise the field shows different text while the table silently
  // stays filtered by whatever shop was previously selected.
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

  deleteSupply(item: SupplyListItem): void {
    this.confirmDialog
      .confirm({
        title: 'Delete Supply',
        message: `Delete invoice "${item.invoiceNo}"? This will reverse the shop ledger entries automatically.`,
        destructive: true,
        confirmLabel: 'Delete'
      })
      .subscribe((confirmed) => {
        if (!confirmed) return;
        this.service.delete(item.supplyID).subscribe({
          next: () => {
            this.notification.success('Supply deleted and ledgers updated.');
            this.load();
          }
        });
      });
  }

  editSupply(item: SupplyListItem): void {
    this.router.navigate(['/supply', item.supplyID, 'edit']);
  }

  exportExcel(): void {
    this.exportService.exportToExcel(
      this.items(),
      [
        { header: 'Date', field: 'supplyDate' },
        { header: 'Invoice No', field: 'invoiceNo' },
        { header: 'Shop', field: 'shopName' },
        { header: 'Amount', field: 'totalAmount' }
      ],
      'supply'
    );
  }

  exportPdf(): void {
    this.exportService.exportToPdf(
      this.items(),
      [
        { header: 'Date', field: 'supplyDate' },
        { header: 'Invoice No', field: 'invoiceNo' },
        { header: 'Shop', field: 'shopName' },
        { header: 'Amount', field: 'totalAmount' }
      ],
      'supply',
      'Supply Report'
    );
  }
}
