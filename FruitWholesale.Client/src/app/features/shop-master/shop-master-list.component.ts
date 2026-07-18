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
import { MatChipsModule } from '@angular/material/chips';
import { MatDialog } from '@angular/material/dialog';
import { debounceTime, distinctUntilChanged, Subject } from 'rxjs';
import { ShopMasterService } from './shop-master.service';
import { ShopMasterFormComponent } from './shop-master-form.component';
import { ShopMaster } from '../../core/models/master-data.model';
import { PaginationRequest } from '../../core/models/common.model';
import { NotificationService } from '../../core/services/notification.service';
import { ConfirmDialogService } from '../../shared/confirm-dialog/confirm-dialog.service';
import { ExportService } from '../../core/services/export.service';

@Component({
  selector: 'app-shop-master-list',
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
    MatMenuModule,
    MatChipsModule
  ],
  templateUrl: './shop-master-list.component.html'
})
export class ShopMasterListComponent implements OnInit {
  private readonly service = inject(ShopMasterService);
  private readonly dialog = inject(MatDialog);
  private readonly notification = inject(NotificationService);
  private readonly confirmDialog = inject(ConfirmDialogService);
  private readonly exportService = inject(ExportService);

  @ViewChild(MatPaginator) paginator!: MatPaginator;

  readonly displayedColumns = ['shopName', 'ownerName', 'phone', 'routeName', 'creditLimit', 'currentOutstanding', 'isActive', 'actions'];
  readonly items = signal<ShopMaster[]>([]);
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
      .open(ShopMasterFormComponent, { width: '480px', data: null })
      .afterClosed()
      .subscribe((result) => {
        if (!result) return;
        this.service.create(result).subscribe({
          next: () => {
            this.notification.success('Shop added successfully.');
            this.load();
          }
        });
      });
  }

  openEdit(shop: ShopMaster): void {
    this.dialog
      .open(ShopMasterFormComponent, { width: '480px', data: shop })
      .afterClosed()
      .subscribe((result) => {
        if (!result) return;
        this.service.update(shop.shopID, result).subscribe({
          next: () => {
            this.notification.success('Shop updated successfully.');
            this.load();
          }
        });
      });
  }

  toggleActive(shop: ShopMaster): void {
    const action$ = shop.isActive ? this.service.deactivate(shop.shopID) : this.service.activate(shop.shopID);
    this.confirmDialog
      .confirm({
        title: shop.isActive ? 'Deactivate Shop' : 'Activate Shop',
        message: `Are you sure you want to ${shop.isActive ? 'deactivate' : 'activate'} "${shop.shopName}"?`,
        destructive: shop.isActive
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
        { header: 'Shop Name', field: 'shopName' },
        { header: 'Owner', field: 'ownerName' },
        { header: 'Phone', field: 'phone' },
        { header: 'Credit Limit', field: 'creditLimit' },
        { header: 'Outstanding', field: 'currentOutstanding' }
      ],
      'shops'
    );
  }

  exportPdf(): void {
    this.exportService.exportToPdf(
      this.items(),
      [
        { header: 'Shop Name', field: 'shopName' },
        { header: 'Owner', field: 'ownerName' },
        { header: 'Phone', field: 'phone' },
        { header: 'Outstanding', field: 'currentOutstanding' }
      ],
      'shops',
      'Shop Master'
    );
  }
}
