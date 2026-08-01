import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { CurrencyPipe } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { MatTableModule } from '@angular/material/table';
import { MatPaginatorModule } from '@angular/material/paginator';
import { MatSortModule } from '@angular/material/sort';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';
import { MatSlideToggleModule } from '@angular/material/slide-toggle';
import { MatTooltipModule } from '@angular/material/tooltip';
import { MatProgressBarModule } from '@angular/material/progress-bar';
import { MatMenuModule } from '@angular/material/menu';
import { MatChipsModule } from '@angular/material/chips';
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
  imports: [
    CurrencyPipe,
    FormsModule,
    MatTableModule,
    MatPaginatorModule,
    MatSortModule,
    MatButtonModule,
    MatIconModule,
    MatFormFieldModule,
    MatInputModule,
    MatSelectModule,
    MatSlideToggleModule,
    MatTooltipModule,
    MatProgressBarModule,
    MatMenuModule,
    MatChipsModule
  ],
  templateUrl: './shop-master-list.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class ShopMasterListComponent extends MasterListBase<ShopMaster, SaveShopMaster> {
  private readonly shopService = inject(ShopMasterService);
  private readonly routeService = inject(RouteMasterService);
  private readonly exportService = inject(ExportService);
  private readonly authService = inject(AuthService);

  readonly displayedColumns = ['shopName', 'ownerName', 'phone', 'routeName', 'creditLimit', 'currentOutstanding', 'isActive', 'actions'];

  readonly routes = signal<RouteMaster[]>([]);
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

  onRouteFilterChange(): void {
    this.request.pageNumber = 1;
    this.paginator?.firstPage();
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
    this.openFormDialog(ShopMasterFormComponent, '480px', null);
  }

  openEdit(shop: ShopMaster): void {
    this.openFormDialog(ShopMasterFormComponent, '480px', shop);
  }

  openBalanceAdjustment(shop: ShopMaster): void {
    this.dialog
      .open(ShopBalanceAdjustmentComponent, { width: '440px', data: shop })
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
