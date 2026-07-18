import { Component, OnInit, ViewChild, inject, signal } from '@angular/core';
import { CurrencyPipe, DatePipe } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { MatTableModule } from '@angular/material/table';
import { MatPaginator, MatPaginatorModule, PageEvent } from '@angular/material/paginator';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';
import { MatChipsModule } from '@angular/material/chips';
import { MatTooltipModule } from '@angular/material/tooltip';
import { MatProgressBarModule } from '@angular/material/progress-bar';
import { MatDialog } from '@angular/material/dialog';
import { CollectionService } from './collection.service';
import { CollectionFormComponent } from './collection-form.component';
import { ShopMasterService } from '../shop-master/shop-master.service';
import { Collection } from '../../core/models/transactions.model';
import { ShopMaster } from '../../core/models/master-data.model';
import { PaginationRequest } from '../../core/models/common.model';
import { NotificationService } from '../../core/services/notification.service';
import { ConfirmDialogService } from '../../shared/confirm-dialog/confirm-dialog.service';

@Component({
  selector: 'app-collection-list',
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
    MatSelectModule,
    MatChipsModule,
    MatTooltipModule,
    MatProgressBarModule
  ],
  templateUrl: './collection-list.component.html'
})
export class CollectionListComponent implements OnInit {
  private readonly service = inject(CollectionService);
  private readonly shopService = inject(ShopMasterService);
  private readonly dialog = inject(MatDialog);
  private readonly notification = inject(NotificationService);
  private readonly confirmDialog = inject(ConfirmDialogService);

  @ViewChild(MatPaginator) paginator!: MatPaginator;

  readonly displayedColumns = ['collectionDate', 'shopName', 'amountReceived', 'discountAmount', 'paymentMode', 'actions'];
  readonly items = signal<Collection[]>([]);
  readonly totalCount = signal(0);
  readonly loading = signal(false);
  readonly shops = signal<ShopMaster[]>([]);

  shopId: number | null = null;

  private readonly request: PaginationRequest = { pageNumber: 1, pageSize: 10 };

  ngOnInit(): void {
    this.shopService.getAllActive().subscribe((shops) => this.shops.set(shops));
    this.load();
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
    this.service.getPaged(this.request, this.shopId).subscribe({
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
      .open(CollectionFormComponent, { width: '480px', data: null })
      .afterClosed()
      .subscribe((result) => {
        if (!result) return;
        this.service.create(result).subscribe({
          next: () => {
            this.notification.success('Collection recorded. Shop and Cash ledgers updated.');
            this.load();
          }
        });
      });
  }

  openEdit(item: Collection): void {
    this.dialog
      .open(CollectionFormComponent, { width: '480px', data: item })
      .afterClosed()
      .subscribe((result) => {
        if (!result) return;
        this.service.update(item.collectionID, result).subscribe({
          next: () => {
            this.notification.success('Collection updated. Ledgers recalculated.');
            this.load();
          }
        });
      });
  }

  deleteItem(item: Collection): void {
    this.confirmDialog
      .confirm({
        title: 'Delete Collection',
        message: `Delete this collection of ${item.amountReceived} from ${item.shopName}? Ledgers will be reversed automatically.`,
        destructive: true,
        confirmLabel: 'Delete'
      })
      .subscribe((confirmed) => {
        if (!confirmed) return;
        this.service.delete(item.collectionID).subscribe({
          next: () => {
            this.notification.success('Collection deleted and ledgers updated.');
            this.load();
          }
        });
      });
  }
}
