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
import { MatChipsModule } from '@angular/material/chips';
import { MatDialog } from '@angular/material/dialog';
import { debounceTime, distinctUntilChanged, Subject } from 'rxjs';
import { RouteMasterService } from './route-master.service';
import { RouteMasterFormComponent } from './route-master-form.component';
import { RouteMaster } from '../../core/models/master-data.model';
import { PaginationRequest } from '../../core/models/common.model';
import { NotificationService } from '../../core/services/notification.service';
import { ConfirmDialogService } from '../../shared/confirm-dialog/confirm-dialog.service';

@Component({
  selector: 'app-route-master-list',
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
    MatChipsModule
  ],
  templateUrl: './route-master-list.component.html'
})
export class RouteMasterListComponent implements OnInit {
  private readonly service = inject(RouteMasterService);
  private readonly dialog = inject(MatDialog);
  private readonly notification = inject(NotificationService);
  private readonly confirmDialog = inject(ConfirmDialogService);

  @ViewChild(MatPaginator) paginator!: MatPaginator;

  readonly displayedColumns = ['routeName', 'description', 'shopCount', 'isActive', 'actions'];
  readonly items = signal<RouteMaster[]>([]);
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
      .open(RouteMasterFormComponent, { width: '460px', data: null })
      .afterClosed()
      .subscribe((result) => {
        if (!result) return;
        this.service.create(result).subscribe({
          next: () => {
            this.notification.success('Route added successfully.');
            this.load();
          }
        });
      });
  }

  openEdit(route: RouteMaster): void {
    this.dialog
      .open(RouteMasterFormComponent, { width: '460px', data: route })
      .afterClosed()
      .subscribe((result) => {
        if (!result) return;
        this.service.update(route.routeID, result).subscribe({
          next: () => {
            this.notification.success('Route updated successfully.');
            this.load();
          }
        });
      });
  }

  toggleActive(route: RouteMaster): void {
    const action$ = route.isActive ? this.service.deactivate(route.routeID) : this.service.activate(route.routeID);
    this.confirmDialog
      .confirm({
        title: route.isActive ? 'Deactivate Route' : 'Activate Route',
        message: `Are you sure you want to ${route.isActive ? 'deactivate' : 'activate'} "${route.routeName}"?`,
        destructive: route.isActive
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
}
