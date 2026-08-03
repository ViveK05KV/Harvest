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
import { debounceTime, distinctUntilChanged, Subject } from 'rxjs';
import { SupplierReturnService } from './supplier-return.service';
import { SupplierMasterService } from '../supplier-master/supplier-master.service';
import { SupplierReturnListItem } from '../../core/models/transactions.model';
import { SupplierMaster } from '../../core/models/master-data.model';
import { PaginationRequest } from '../../core/models/common.model';
import { NotificationService } from '../../core/services/notification.service';
import { ConfirmDialogService } from '../../shared/confirm-dialog/confirm-dialog.service';
import { toIso } from '../../core/utils/date.util';

@Component({
  selector: 'app-supplier-return-list',
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
    MatProgressBarModule
  ],
  templateUrl: './supplier-return-list.component.html'
})
export class SupplierReturnListComponent implements OnInit {
  private readonly service = inject(SupplierReturnService);
  private readonly supplierService = inject(SupplierMasterService);
  private readonly notification = inject(NotificationService);
  private readonly confirmDialog = inject(ConfirmDialogService);
  private readonly router = inject(Router);

  @ViewChild(MatPaginator) paginator!: MatPaginator;

  readonly displayedColumns = ['returnDate', 'referenceNo', 'supplierName', 'purchaseInvoiceNo', 'totalAmount', 'actions'];
  readonly items = signal<SupplierReturnListItem[]>([]);
  readonly totalCount = signal(0);
  readonly loading = signal(false);
  readonly suppliers = signal<SupplierMaster[]>([]);

  supplierId: number | null = null;
  supplierSearch = '';
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
    this.supplierService.getAllActive().subscribe((suppliers) => this.suppliers.set(suppliers));
    this.load();
  }

  onSearch(term: string): void {
    this.searchSubject.next(term);
  }

  onFilterChange(): void {
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

  onPage(event: PageEvent): void {
    this.request.pageNumber = event.pageIndex + 1;
    this.request.pageSize = event.pageSize;
    this.load();
  }

  load(): void {
    this.loading.set(true);
    const from = this.fromDate ? toIso(this.fromDate) : null;
    const to = this.toDate ? toIso(this.toDate) : null;
    this.service.getPaged(this.request, this.supplierId, from, to).subscribe({
      next: (result) => {
        this.items.set(result.items);
        this.totalCount.set(result.totalCount);
        this.loading.set(false);
      },
      error: () => this.loading.set(false)
    });
  }

  deleteSupplierReturn(item: SupplierReturnListItem): void {
    this.confirmDialog
      .confirm({
        title: 'Delete Supplier Return',
        message: `Delete return "${item.referenceNo}"? This will reverse the supplier ledger and stock entries automatically.`,
        destructive: true,
        confirmLabel: 'Delete'
      })
      .subscribe((confirmed) => {
        if (!confirmed) return;
        this.service.delete(item.supplierReturnID).subscribe({
          next: () => {
            this.notification.success('Supplier return deleted and ledgers updated.');
            this.load();
          }
        });
      });
  }

  editSupplierReturn(item: SupplierReturnListItem): void {
    this.router.navigate(['/supplier-returns', item.supplierReturnID, 'edit']);
  }
}
