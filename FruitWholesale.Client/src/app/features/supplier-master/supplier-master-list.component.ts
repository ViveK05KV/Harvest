import { Component, OnInit, ViewChild, inject, signal } from '@angular/core';
import { CurrencyPipe } from '@angular/common';
import { MatTableModule } from '@angular/material/table';
import { MatPaginator, MatPaginatorModule, PageEvent } from '@angular/material/paginator';
import { MatSortModule, Sort } from '@angular/material/sort';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSlideToggleModule } from '@angular/material/slide-toggle';
import { MatTooltipModule } from '@angular/material/tooltip';
import { MatProgressBarModule } from '@angular/material/progress-bar';
import { MatMenuModule } from '@angular/material/menu';
import { MatDialog } from '@angular/material/dialog';
import { debounceTime, distinctUntilChanged, Subject } from 'rxjs';
import { SupplierMasterService } from './supplier-master.service';
import { SupplierMasterFormComponent } from './supplier-master-form.component';
import { SupplierMaster } from '../../core/models/master-data.model';
import { PaginationRequest } from '../../core/models/common.model';
import { NotificationService } from '../../core/services/notification.service';
import { ConfirmDialogService } from '../../shared/confirm-dialog/confirm-dialog.service';
import { ExportService } from '../../core/services/export.service';

@Component({
  selector: 'app-supplier-master-list',
  standalone: true,
  imports: [
    CurrencyPipe,
    MatTableModule,
    MatPaginatorModule,
    MatSortModule,
    MatButtonModule,
    MatIconModule,
    MatFormFieldModule,
    MatInputModule,
    MatSlideToggleModule,
    MatTooltipModule,
    MatProgressBarModule,
    MatMenuModule
  ],
  templateUrl: './supplier-master-list.component.html'
})
export class SupplierMasterListComponent implements OnInit {
  private readonly service = inject(SupplierMasterService);
  private readonly dialog = inject(MatDialog);
  private readonly notification = inject(NotificationService);
  private readonly confirmDialog = inject(ConfirmDialogService);
  private readonly exportService = inject(ExportService);

  @ViewChild(MatPaginator) paginator!: MatPaginator;

  readonly displayedColumns = ['supplierName', 'phone', 'currentOutstanding', 'isActive', 'actions'];
  readonly items = signal<SupplierMaster[]>([]);
  readonly totalCount = signal(0);
  readonly loading = signal(false);

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
    this.load();
  }

  onSearch(term: string): void {
    this.searchSubject.next(term);
  }

  onPage(event: PageEvent): void {
    this.request.pageNumber = event.pageIndex + 1;
    this.request.pageSize = event.pageSize;
    this.load();
  }

  onSort(sort: Sort): void {
    this.request.sortBy = sort.direction ? sort.active : null;
    this.request.sortDescending = sort.direction === 'desc';
    this.load();
  }

  load(): void {
    this.loading.set(true);
    this.service.getPaged(this.request).subscribe({
      next: (result) => {
        this.items.set(result.items);
        this.totalCount.set(result.totalCount);
        this.loading.set(false);
      },
      error: () => this.loading.set(false)
    });
  }

  openCreate(): void {
    this.dialog
      .open(SupplierMasterFormComponent, { width: '480px', data: null })
      .afterClosed()
      .subscribe((result) => {
        if (!result) return;
        this.service.create(result).subscribe({
          next: () => {
            this.notification.success('Supplier added successfully.');
            this.load();
          }
        });
      });
  }

  openEdit(supplier: SupplierMaster): void {
    this.dialog
      .open(SupplierMasterFormComponent, { width: '480px', data: supplier })
      .afterClosed()
      .subscribe((result) => {
        if (!result) return;
        this.service.update(supplier.supplierID, result).subscribe({
          next: () => {
            this.notification.success('Supplier updated successfully.');
            this.load();
          }
        });
      });
  }

  toggleActive(supplier: SupplierMaster): void {
    const action$ = supplier.isActive ? this.service.deactivate(supplier.supplierID) : this.service.activate(supplier.supplierID);
    this.confirmDialog
      .confirm({
        title: supplier.isActive ? 'Deactivate Supplier' : 'Activate Supplier',
        message: `Are you sure you want to ${supplier.isActive ? 'deactivate' : 'activate'} "${supplier.supplierName}"?`,
        destructive: supplier.isActive
      })
      .subscribe((confirmed) => {
        if (!confirmed) return;
        action$.subscribe({
          next: () => {
            this.notification.success('Status updated.');
            this.load();
          }
        });
      });
  }

  exportExcel(): void {
    this.exportService.exportToExcel(
      this.items(),
      [
        { header: 'Supplier Name', field: 'supplierName' },
        { header: 'Phone', field: 'phone' },
        { header: 'Outstanding', field: 'currentOutstanding' }
      ],
      'suppliers'
    );
  }

  exportPdf(): void {
    this.exportService.exportToPdf(
      this.items(),
      [
        { header: 'Supplier Name', field: 'supplierName' },
        { header: 'Phone', field: 'phone' },
        { header: 'Outstanding', field: 'currentOutstanding' }
      ],
      'suppliers',
      'Supplier Master'
    );
  }
}
