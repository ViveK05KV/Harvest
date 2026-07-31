import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
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
import { FruitMasterService } from './fruit-master.service';
import { FruitMasterFormComponent } from './fruit-master-form.component';
import { FruitMaster, SaveFruitMaster } from '../../core/models/master-data.model';
import { ExportService } from '../../core/services/export.service';

@Component({
  selector: 'app-fruit-master-list',
  standalone: true,
  imports: [
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
  templateUrl: './fruit-master-list.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class FruitMasterListComponent extends MasterListBase<FruitMaster, SaveFruitMaster> {
  private readonly exportService = inject(ExportService);

  readonly displayedColumns = ['fruitName', 'unit', 'isActive', 'actions'];

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

  openCreate(): void {
    this.openFormDialog(FruitMasterFormComponent, '420px', null);
  }

  openEdit(fruit: FruitMaster): void {
    this.openFormDialog(FruitMasterFormComponent, '420px', fruit);
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
