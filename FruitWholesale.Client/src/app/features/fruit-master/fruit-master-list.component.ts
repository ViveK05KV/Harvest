import { Component, OnInit, ViewChild, inject, signal } from '@angular/core';
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
import { MatDialog } from '@angular/material/dialog';
import { MatMenuModule } from '@angular/material/menu';
import { debounceTime, distinctUntilChanged, Subject } from 'rxjs';
import { FruitMasterService } from './fruit-master.service';
import { FruitMasterFormComponent } from './fruit-master-form.component';
import { FruitMaster } from '../../core/models/master-data.model';
import { PaginationRequest } from '../../core/models/common.model';
import { NotificationService } from '../../core/services/notification.service';
import { ConfirmDialogService } from '../../shared/confirm-dialog/confirm-dialog.service';
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
  templateUrl: './fruit-master-list.component.html'
})
export class FruitMasterListComponent implements OnInit {
  private readonly service = inject(FruitMasterService);
  private readonly dialog = inject(MatDialog);
  private readonly notification = inject(NotificationService);
  private readonly confirmDialog = inject(ConfirmDialogService);
  private readonly exportService = inject(ExportService);

  @ViewChild(MatPaginator) paginator!: MatPaginator;

  readonly displayedColumns = ['fruitName', 'unit', 'isActive', 'actions'];
  readonly items = signal<FruitMaster[]>([]);
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
      .open(FruitMasterFormComponent, { width: '420px', data: null })
      .afterClosed()
      .subscribe((result) => {
        if (!result) return;
        this.service.create(result).subscribe({
          next: () => {
            this.notification.success('Fruit added successfully.');
            this.load();
          }
        });
      });
  }

  openEdit(fruit: FruitMaster): void {
    this.dialog
      .open(FruitMasterFormComponent, { width: '420px', data: fruit })
      .afterClosed()
      .subscribe((result) => {
        if (!result) return;
        this.service.update(fruit.fruitID, result).subscribe({
          next: () => {
            this.notification.success('Fruit updated successfully.');
            this.load();
          }
        });
      });
  }

  toggleActive(fruit: FruitMaster): void {
    const action$ = fruit.isActive ? this.service.deactivate(fruit.fruitID) : this.service.activate(fruit.fruitID);
    this.confirmDialog
      .confirm({
        title: fruit.isActive ? 'Deactivate Fruit' : 'Activate Fruit',
        message: `Are you sure you want to ${fruit.isActive ? 'deactivate' : 'activate'} "${fruit.fruitName}"?`,
        destructive: fruit.isActive
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
