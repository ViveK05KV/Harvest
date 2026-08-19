import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { CurrencyPipe } from '@angular/common';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressBarModule } from '@angular/material/progress-bar';
import { Sort } from '@angular/material/sort';
import { MasterListBase } from '../../core/base/master-list-base';
import { SupplierMasterService } from './supplier-master.service';
import { SupplierMasterFormComponent } from './supplier-master-form.component';
import { SupplierBalanceAdjustmentComponent } from './supplier-balance-adjustment.component';
import { SupplierMaster, SaveSupplierMaster } from '../../core/models/master-data.model';
import { ExportService } from '../../core/services/export.service';
import { AuthService } from '../../core/services/auth.service';

@Component({
  selector: 'app-supplier-master-list',
  standalone: true,
  imports: [CurrencyPipe, MatIconModule, MatProgressBarModule],
  templateUrl: './supplier-master-list.component.html',
  styleUrl: './supplier-master-list.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class SupplierMasterListComponent extends MasterListBase<SupplierMaster, SaveSupplierMaster> {
  private readonly supplierService = inject(SupplierMasterService);
  private readonly exportService = inject(ExportService);
  private readonly authService = inject(AuthService);

  readonly sortDirection = signal<'asc' | 'desc' | ''>('');
  readonly canAdjustBalance = this.authService.hasRole('Admin', 'Accountant');

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

  rangeLabel(): string {
    const total = this.totalCount();
    if (total === 0) return 'No suppliers';
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
    this.onSort({ active: 'supplierName', direction: next } as Sort);
  }

  openCreate(): void {
    this.openFormDialog(SupplierMasterFormComponent, '480px', null);
  }

  openEdit(supplier: SupplierMaster): void {
    this.openFormDialog(SupplierMasterFormComponent, '480px', supplier);
  }

  openBalanceAdjustment(supplier: SupplierMaster): void {
    this.dialog
      .open(SupplierBalanceAdjustmentComponent, { width: '480px', maxWidth: '95vw', data: supplier, autoFocus: 'dialog' })
      .afterClosed()
      .subscribe((result) => {
        if (!result) return;
        this.supplierService.applyBalanceAdjustment(supplier.supplierID, result).subscribe({
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
