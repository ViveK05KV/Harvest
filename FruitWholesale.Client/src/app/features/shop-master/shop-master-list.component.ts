import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { CurrencyPipe } from '@angular/common';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressBarModule } from '@angular/material/progress-bar';
import { Sort } from '@angular/material/sort';
import { MasterListBase } from '../../core/base/master-list-base';
import { ShopMasterService } from './shop-master.service';
import { ShopMasterFormComponent } from './shop-master-form.component';
import { ShopBalanceAdjustmentComponent } from './shop-balance-adjustment.component';
import { ShopMaster, SaveShopMaster, RouteMaster } from '../../core/models/master-data.model';
import { RouteMasterService } from '../route-master/route-master.service';
import { ExportService } from '../../core/services/export.service';
import { AuthService } from '../../core/services/auth.service';

@Component({
  selector: 'app-shop-master-list',
  standalone: true,
  imports: [CurrencyPipe, MatIconModule, MatProgressBarModule],
  templateUrl: './shop-master-list.component.html',
  styleUrl: './shop-master-list.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class ShopMasterListComponent extends MasterListBase<ShopMaster, SaveShopMaster> {
  private readonly shopService = inject(ShopMasterService);
  private readonly routeService = inject(RouteMasterService);
  private readonly exportService = inject(ExportService);
  private readonly authService = inject(AuthService);

  readonly routes = signal<RouteMaster[]>([]);
  readonly sortDirection = signal<'asc' | 'desc' | ''>('');
  routeId: number | null = null;
  readonly canAdjustBalance = this.authService.hasRole('Admin', 'Accountant');

  constructor() {
    super(inject(ShopMasterService), {
      idOf: (s) => s.shopID,
      nameOf: (s) => s.shopName,
      isActiveOf: (s) => s.isActive,
      entityLabel: 'Shop',
      createdMessage: 'Shop added successfully.',
      updatedMessage: 'Shop updated successfully.'
    });
    this.routeService.getAllActive().subscribe((routes) => this.routes.set(routes));
  }

  rangeLabel(): string {
    const total = this.totalCount();
    if (total === 0) return 'No shops';
    const start = (this.request.pageNumber - 1) * this.request.pageSize + 1;
    const end = Math.min(start + this.request.pageSize - 1, total);
    return `${start}–${end} of ${total}`;
  }

  prevPage(): void {
    if (this.request.pageNumber <= 1) return;
    this.request.pageNumber--;
    this.load();
  }

  nextPage(): void {
    if (this.request.pageNumber * this.request.pageSize >= this.totalCount()) return;
    this.request.pageNumber++;
    this.load();
  }

  toggleSort(): void {
    const next = this.sortDirection() === 'asc' ? 'desc' : this.sortDirection() === 'desc' ? '' : 'asc';
    this.sortDirection.set(next);
    this.onSort({ active: 'shopName', direction: next } as Sort);
  }

  onRouteChange(value: string): void {
    this.routeId = value ? Number(value) : null;
    this.onRouteFilterChange();
  }

  onRouteFilterChange(): void {
    this.request.pageNumber = 1;
    this.load();
  }

  override load(): void {
    this.loading.set(true);
    this.shopService.getPaged(this.request, this.routeId).subscribe({
      next: (result) => {
        this.items.set(result.items);
        this.totalCount.set(result.totalCount);
        this.loading.set(false);
      },
      error: () => this.loading.set(false)
    });
  }

  openCreate(): void {
    this.openFormDialog(ShopMasterFormComponent, '520px', null);
  }

  openEdit(shop: ShopMaster): void {
    this.openFormDialog(ShopMasterFormComponent, '520px', shop);
  }

  openBalanceAdjustment(shop: ShopMaster): void {
    this.dialog
      .open(ShopBalanceAdjustmentComponent, { width: '480px', maxWidth: '95vw', data: shop, autoFocus: 'dialog' })
      .afterClosed()
      .subscribe((result) => {
        if (!result) return;
        this.shopService.applyBalanceAdjustment(shop.shopID, result).subscribe({
          next: () => {
            this.notification.success('Balance adjustment applied.');
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
