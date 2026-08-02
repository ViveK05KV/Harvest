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
import { MatDatepickerModule } from '@angular/material/datepicker';
import { MatNativeDateModule } from '@angular/material/core';
import { MatTooltipModule } from '@angular/material/tooltip';
import { MatProgressBarModule } from '@angular/material/progress-bar';
import { MatMenuModule } from '@angular/material/menu';
import { debounceTime, distinctUntilChanged, Subject } from 'rxjs';
import { PurchaseService } from './purchase.service';
import { SupplierMasterService } from '../supplier-master/supplier-master.service';
import { PurchaseListItem } from '../../core/models/transactions.model';
import { SupplierMaster } from '../../core/models/master-data.model';
import { PaginationRequest } from '../../core/models/common.model';
import { NotificationService } from '../../core/services/notification.service';
import { ConfirmDialogService } from '../../shared/confirm-dialog/confirm-dialog.service';
import { ExportService } from '../../core/services/export.service';
import { toIso } from '../../core/utils/date.util';

@Component({
  selector: 'app-purchase-list',
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
    MatDatepickerModule,
    MatNativeDateModule,
    MatTooltipModule,
    MatProgressBarModule,
    MatMenuModule
  ],
  templateUrl: './purchase-list.component.html'
})
export class PurchaseListComponent implements OnInit {
  private readonly service = inject(PurchaseService);
  private readonly supplierService = inject(SupplierMasterService);
  private readonly notification = inject(NotificationService);
  private readonly confirmDialog = inject(ConfirmDialogService);
  private readonly exportService = inject(ExportService);
  private readonly router = inject(Router);

  @ViewChild(MatPaginator) paginator!: MatPaginator;

  readonly displayedColumns = ['purchaseDate', 'invoiceNo', 'supplierName', 'totalAmount', 'actions'];
  readonly items = signal<PurchaseListItem[]>([]);
  readonly totalCount = signal(0);
  readonly loading = signal(false);
  readonly suppliers = signal<SupplierMaster[]>([]);

  supplierId: number | null = null;
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

  deletePurchase(item: PurchaseListItem): void {
    this.confirmDialog
      .confirm({
        title: 'Delete Purchase',
        message: `Delete invoice "${item.invoiceNo}"? This will reverse the supplier ledger entries automatically.`,
        destructive: true,
        confirmLabel: 'Delete'
      })
      .subscribe((confirmed) => {
        if (!confirmed) return;
        this.service.delete(item.purchaseID).subscribe({
          next: () => {
            this.notification.success('Purchase deleted and ledgers updated.');
            this.load();
          }
        });
      });
  }

  editPurchase(item: PurchaseListItem): void {
    this.router.navigate(['/purchase', item.purchaseID, 'edit']);
  }

  exportExcel(): void {
    this.exportService.exportToExcel(
      this.items(),
      [
        { header: 'Date', field: 'purchaseDate' },
        { header: 'Invoice No', field: 'invoiceNo' },
        { header: 'Supplier', field: 'supplierName' },
        { header: 'Amount', field: 'totalAmount' }
      ],
      'purchase'
    );
  }

  exportPdf(): void {
    this.exportService.exportToPdf(
      this.items(),
      [
        { header: 'Date', field: 'purchaseDate' },
        { header: 'Invoice No', field: 'invoiceNo' },
        { header: 'Supplier', field: 'supplierName' },
        { header: 'Amount', field: 'totalAmount' }
      ],
      'purchase',
      'Purchase Report'
    );
  }
}
