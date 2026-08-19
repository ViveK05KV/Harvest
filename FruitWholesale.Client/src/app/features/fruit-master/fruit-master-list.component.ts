import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressBarModule } from '@angular/material/progress-bar';
import { Sort } from '@angular/material/sort';
import { MasterListBase } from '../../core/base/master-list-base';
import { FruitMasterService } from './fruit-master.service';
import { FruitMasterFormComponent } from './fruit-master-form.component';
import { FruitMaster, SaveFruitMaster } from '../../core/models/master-data.model';
import { ExportService } from '../../core/services/export.service';

@Component({
  selector: 'app-fruit-master-list',
  standalone: true,
  imports: [MatIconModule, MatProgressBarModule],
  templateUrl: './fruit-master-list.component.html',
  styleUrl: './fruit-master-list.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class FruitMasterListComponent extends MasterListBase<FruitMaster, SaveFruitMaster> {
  private readonly exportService = inject(ExportService);

  readonly sortDirection = signal<'asc' | 'desc' | ''>('');

  constructor() {
    super(inject(FruitMasterService), {
      idOf: (f) => f.fruitID,
      nameOf: (f) => f.fruitName,
      isActiveOf: (f) => f.isActive,
      entityLabel: 'Fruit',
      createdMessage: 'Fruit added successfully.',
      updatedMessage: 'Fruit updated successfully.'
    });
  }

  rangeLabel(): string {
    const total = this.totalCount();
    if (total === 0) return 'No fruits';
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
    this.onSort({ active: 'fruitName', direction: next } as Sort);
  }

  openCreate(): void {
    this.openFormDialog(FruitMasterFormComponent, '460px', null);
  }

  openEdit(fruit: FruitMaster): void {
    this.openFormDialog(FruitMasterFormComponent, '460px', fruit);
  }

  exportExcel(): void {
    this.exportService.exportToExcel(
      this.items(),
      [
        { header: 'Fruit Name', field: 'fruitName' },
        { header: 'Unit', field: 'unit' },
        { header: 'Active', field: 'isActive' }
      ],
      'fruit-master'
    );
  }

  exportPdf(): void {
    this.exportService.exportToPdf(
      this.items(),
      [
        { header: 'Fruit Name', field: 'fruitName' },
        { header: 'Unit', field: 'unit' }
      ],
      'fruit-master',
      'Fruit Master'
    );
  }
}
