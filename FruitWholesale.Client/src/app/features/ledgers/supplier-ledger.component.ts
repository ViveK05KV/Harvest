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
import { MatTooltipModule } from '@angular/material/tooltip';
import { LedgerService } from './ledger.service';
import { SupplierMasterService } from '../supplier-master/supplier-master.service';
import { SupplierLedgerEntry, ledgerParticulars } from '../../core/models/ledger.model';
import { SupplierMaster } from '../../core/models/master-data.model';
import { PaginationRequest } from '../../core/models/common.model';
import { ExportService } from '../../core/services/export.service';
import { toIso } from '../../core/utils/date.util';

@Component({
  selector: 'app-supplier-ledger',
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
    MatTooltipModule
  ],
  templateUrl: './supplier-ledger.component.html'
})
export class SupplierLedgerComponent implements OnInit {
  private readonly ledgerService = inject(LedgerService);
  private readonly supplierService = inject(SupplierMasterService);
  private readonly exportService = inject(ExportService);

  @ViewChild(MatPaginator) paginator!: MatPaginator;

  readonly displayedColumns = ['transactionDate', 'particulars', 'purchase', 'payment', 'runningBalance'];
  readonly particulars = ledgerParticulars;
  readonly suppliers = signal<SupplierMaster[]>([]);
  readonly items = signal<SupplierLedgerEntry[]>([]);
  readonly totalCount = signal(0);
  readonly loading = signal(false);

  supplierId: number | null = null;
  supplierSearch = '';
  fromDate: Date | null = null;
  toDate: Date | null = null;

  private readonly request: PaginationRequest = { pageNumber: 1, pageSize: 20 };

  ngOnInit(): void {
    this.supplierService.getAllActive().subscribe((suppliers) => {
      this.suppliers.set(suppliers);
      if (suppliers.length > 0) {
        this.supplierId = suppliers[0].supplierID;
        this.supplierSearch = suppliers[0].supplierName;
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

  netBalanceTooltip(supplier: SupplierMaster): string {
    return supplier.linkedShopID
      ? `Combined position with linked Shop: ${supplier.linkedShopName}`
      : `Outstanding balance owed to ${supplier.supplierName}`;
  }

  onFilterChange(): void {
    if (!this.supplierId) return;
    this.request.pageNumber = 1;
    this.load();
  }

  filteredSuppliers(search: string | null | undefined): SupplierMaster[] {
    const term = (search ?? '').trim().toLowerCase();
    if (!term) return this.suppliers();
    return this.suppliers().filter((s) => s.supplierName.toLowerCase().includes(term));
  }

  onSupplierFilterSelected(event: MatAutocompleteSelectedEvent): void {
    const supplierId = event.option.value as number | null;
    this.supplierId = supplierId;
    this.supplierSearch = supplierId == null ? '' : (this.suppliers().find((s) => s.supplierID === supplierId)?.supplierName ?? '');
    this.onFilterChange();
  }

  // Same as ShopLedgerComponent.onShopSearchFocus/Blur: clears on focus/click (or
  // via the dropdown arrow) so the panel opens showing the full list instead of
  // narrowed down to the already-selected name, but only when the field is
  // showing that settled name rather than a query still being typed; restores
  // the name on blur if nothing new was picked.
  onSupplierSearchFocus(): void {
    if (this.supplierSearch !== (this.selectedSupplier()?.supplierName ?? '')) return;
    this.supplierSearch = '';
  }

  onSupplierSearchBlur(): void {
    if (this.supplierSearch) return;
    this.supplierSearch = this.selectedSupplier()?.supplierName ?? '';
  }

  // Same as ShopLedgerComponent.showAllShops: the dropdown arrow always shows the
  // full list regardless of any in-progress query.
  showAllSuppliers(): void {
    this.supplierSearch = '';
  }

  onPage(event: PageEvent): void {
    this.request.pageNumber = event.pageIndex + 1;
    this.request.pageSize = event.pageSize;
    this.load();
  }

  load(): void {
    if (!this.supplierId) return;
    this.loading.set(true);
    const from = this.fromDate ? toIso(this.fromDate) : null;
    const to = this.toDate ? toIso(this.toDate) : null;
    this.ledgerService.getSupplierLedger(this.supplierId, this.request, from, to).subscribe({
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
        { header: 'Purchase', field: 'debit' },
        { header: 'Payment', field: 'credit' },
        { header: 'Balance', field: 'runningBalance' }
      ],
      'supplier-ledger'
    );
  }
}
