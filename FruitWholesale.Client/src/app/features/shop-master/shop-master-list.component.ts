import { Component, inject } from '@angular/core';
import { CurrencyPipe } from '@angular/common';
import { MatTableModule } from '@angular/material/table';
import { MatPaginatorModule } from '@angular/material/paginator';
import { MatSortModule } from '@angular/material/sort';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSlideToggleModule } from '@angular/material/slide-toggle';
import { MatTooltipModule } from '@angular/material/tooltip';
import { MatProgressBarModule } from '@angular/material/progress-bar';
import { MatMenuModule } from '@angular/material/menu';
import { MatChipsModule } from '@angular/material/chips';
import { MasterListBase } from '../../core/base/master-list-base';
import { ShopMasterService } from './shop-master.service';
import { ShopMasterFormComponent } from './shop-master-form.component';
import { ShopMaster, SaveShopMaster } from '../../core/models/master-data.model';
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
export class ShopMasterListComponent extends MasterListBase<ShopMaster, SaveShopMaster> {
  private readonly exportService = inject(ExportService);

  readonly displayedColumns = ['shopName', 'ownerName', 'phone', 'routeName', 'creditLimit', 'currentOutstanding', 'isActive', 'actions'];

  constructor() {
    super(inject(ShopMasterService), {
      idOf: (s) => s.shopID,
      nameOf: (s) => s.shopName,
      isActiveOf: (s) => s.isActive,
      entityLabel: 'Shop',
      createdMessage: 'Shop added successfully.',
      updatedMessage: 'Shop updated successfully.'
    });
  }

  openCreate(): void {
    this.openFormDialog(ShopMasterFormComponent, '480px', null);
  }

  openEdit(shop: ShopMaster): void {
    this.openFormDialog(ShopMasterFormComponent, '480px', shop);
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
