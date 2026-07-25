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
import { MasterListBase } from '../../core/base/master-list-base';
import { SupplierMasterService } from './supplier-master.service';
import { SupplierMasterFormComponent } from './supplier-master-form.component';
import { SupplierMaster, SaveSupplierMaster } from '../../core/models/master-data.model';
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
export class SupplierMasterListComponent extends MasterListBase<SupplierMaster, SaveSupplierMaster> {
  private readonly exportService = inject(ExportService);

  readonly displayedColumns = ['supplierName', 'phone', 'currentOutstanding', 'isActive', 'actions'];

  constructor() {
    super(inject(SupplierMasterService), {
      idOf: (s) => s.supplierID,
      nameOf: (s) => s.supplierName,
      isActiveOf: (s) => s.isActive,
      entityLabel: 'Supplier',
      createdMessage: 'Supplier added successfully.',
      updatedMessage: 'Supplier updated successfully.'
    });
  }

  openCreate(): void {
    this.openFormDialog(SupplierMasterFormComponent, '480px', null);
  }

  openEdit(supplier: SupplierMaster): void {
    this.openFormDialog(SupplierMasterFormComponent, '480px', supplier);
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
