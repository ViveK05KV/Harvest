import { Component, OnInit, computed, inject, signal } from '@angular/core';
import { CurrencyPipe, DatePipe } from '@angular/common';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressBarModule } from '@angular/material/progress-bar';
import { MatDialog } from '@angular/material/dialog';
import { CollectionService } from './collection.service';
import { CollectionFormComponent } from './collection-form.component';
import { SettleCollectionsDialogComponent } from './settle-collections-dialog.component';
import { ShopMasterService } from '../shop-master/shop-master.service';
import { Collection } from '../../core/models/transactions.model';
import { ShopMaster } from '../../core/models/master-data.model';
import { PaginationRequest } from '../../core/models/common.model';
import { NotificationService } from '../../core/services/notification.service';
import { ConfirmDialogService } from '../../shared/confirm-dialog/confirm-dialog.service';

@Component({
  selector: 'app-collection-list',
  standalone: true,
  imports: [CurrencyPipe, DatePipe, MatIconModule, MatProgressBarModule],
  templateUrl: './collection-list.component.html',
  styleUrl: './collection-list.component.scss'
})
export class CollectionListComponent implements OnInit {
  private readonly service = inject(CollectionService);
  private readonly shopService = inject(ShopMasterService);
  private readonly dialog = inject(MatDialog);
  private readonly notification = inject(NotificationService);
  private readonly confirmDialog = inject(ConfirmDialogService);

  readonly items = signal<Collection[]>([]);
  readonly totalCount = signal(0);
  readonly loading = signal(false);
  readonly shops = signal<ShopMaster[]>([]);

  readonly pageIndex = signal(0);
  readonly pageSize = 10;

  shopId: number | null = null;
  fromDate: string | null = null;
  toDate: string | null = null;

  private readonly request: PaginationRequest = { pageNumber: 1, pageSize: this.pageSize };

  readonly rangeLabel = computed(() => {
    const total = this.totalCount();
    if (total === 0) return 'No collections';
    const start = this.pageIndex() * this.pageSize + 1;
    const end = Math.min(start + this.pageSize - 1, total);
    return `${start}–${end} of ${total}`;
  });

  ngOnInit(): void {
    this.shopService.getAllActive().subscribe((shops) => this.shops.set(shops));
    this.load();
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
    this.shopId = null;
    this.fromDate = null;
    this.toDate = null;
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

  openCreate(): void {
    this.dialog
      .open(CollectionFormComponent, { width: '900px', maxWidth: '95vw', data: null, autoFocus: 'dialog' })
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
    if (item.temporaryStatus === 'Settled') {
      this.notification.error('Settled temporary collections cannot be edited.');
      return;
    }

    this.dialog
      .open(CollectionFormComponent, { width: '900px', maxWidth: '95vw', data: item, autoFocus: 'dialog' })
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
    if (item.temporaryStatus === 'Settled') {
      this.notification.error('Settled temporary collections cannot be deleted.');
      return;
    }
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

  settleDeposits(): void {
    this.dialog
      .open(SettleCollectionsDialogComponent, { width: '700px', maxWidth: '95vw', autoFocus: 'dialog' })
      .afterClosed()
      .subscribe((result) => {
        if (!result) return;
        this.service.settle(result).subscribe({
          next: () => {
            this.notification.success('Temporary collections settled.');
            this.load();
          }
        });
      });
  }
}
