import { Directive, OnInit, Type, ViewChild, inject, signal } from '@angular/core';
import { MatPaginator, PageEvent } from '@angular/material/paginator';
import { Sort } from '@angular/material/sort';
import { MatDialog } from '@angular/material/dialog';
import { debounceTime, distinctUntilChanged, Subject } from 'rxjs';
import { MasterDataApiService } from '../services/master-data-api.service';
import { PaginationRequest } from '../models/common.model';
import { NotificationService } from '../services/notification.service';
import { ConfirmDialogService } from '../../shared/confirm-dialog/confirm-dialog.service';

export interface MasterListConfig<TDto> {
  idOf: (item: TDto) => number;
  nameOf: (item: TDto) => string;
  isActiveOf: (item: TDto) => boolean;
  entityLabel: string;
  createdMessage: string;
  updatedMessage: string;
}

/**
 * Shared search/paginate/sort/CRUD-dialog/toggle-active behavior for the
 * master-data list screens (Shops, Suppliers, Fruits, Routes, Employees,
 * Expense Categories), which all follow the identical shape on top of
 * MasterDataApiService. Concrete list components extend this, supply a
 * MasterListConfig, and keep their own columns/export logic.
 */
@Directive()
export abstract class MasterListBase<TDto, TSaveDto> implements OnInit {
  @ViewChild(MatPaginator) paginator!: MatPaginator;

  protected readonly dialog = inject(MatDialog);
  protected readonly notification = inject(NotificationService);
  protected readonly confirmDialog = inject(ConfirmDialogService);

  readonly items = signal<TDto[]>([]);
  readonly totalCount = signal(0);
  readonly loading = signal(false);

  protected readonly request: PaginationRequest = { pageNumber: 1, pageSize: 10, searchTerm: '' };
  private readonly searchSubject = new Subject<string>();

  protected constructor(
    protected readonly service: MasterDataApiService<TDto, TSaveDto>,
    protected readonly config: MasterListConfig<TDto>
  ) {
    this.searchSubject.pipe(debounceTime(350), distinctUntilChanged()).subscribe((term) => {
      this.request.searchTerm = term;
      this.request.pageNumber = 1;
      this.paginator?.firstPage();
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

  protected openFormDialog(formComponent: Type<unknown>, width: string, data: TDto | null): void {
    this.dialog
      .open(formComponent, { width, data })
      .afterClosed()
      .subscribe((result) => {
        if (!result) return;
        const save$ = data ? this.service.update(this.config.idOf(data), result) : this.service.create(result);
        save$.subscribe({
          next: () => {
            this.notification.success(data ? this.config.updatedMessage : this.config.createdMessage);
            this.load();
          }
        });
      });
  }

  toggleActive(item: TDto): void {
    const isActive = this.config.isActiveOf(item);
    const id = this.config.idOf(item);
    const name = this.config.nameOf(item);
    const action$ = isActive ? this.service.deactivate(id) : this.service.activate(id);
    this.confirmDialog
      .confirm({
        title: isActive ? `Deactivate ${this.config.entityLabel}` : `Activate ${this.config.entityLabel}`,
        message: `Are you sure you want to ${isActive ? 'deactivate' : 'activate'} "${name}"?`,
        destructive: isActive
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
