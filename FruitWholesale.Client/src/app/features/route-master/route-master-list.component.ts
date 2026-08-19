import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressBarModule } from '@angular/material/progress-bar';
import { Sort } from '@angular/material/sort';
import { MasterListBase } from '../../core/base/master-list-base';
import { RouteMasterService } from './route-master.service';
import { RouteMasterFormComponent } from './route-master-form.component';
import { RouteShopsComponent } from './route-shops.component';
import { RouteMaster, SaveRouteMaster } from '../../core/models/master-data.model';

@Component({
  selector: 'app-route-master-list',
  standalone: true,
  imports: [MatIconModule, MatProgressBarModule],
  templateUrl: './route-master-list.component.html',
  styleUrl: './route-master-list.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class RouteMasterListComponent extends MasterListBase<RouteMaster, SaveRouteMaster> {
  readonly sortDirection = signal<'asc' | 'desc' | ''>('');

  constructor() {
    super(inject(RouteMasterService), {
      idOf: (r) => r.routeID,
      nameOf: (r) => r.routeName,
      isActiveOf: (r) => r.isActive,
      entityLabel: 'Route',
      createdMessage: 'Route added successfully.',
      updatedMessage: 'Route updated successfully.'
    });
  }

  rangeLabel(): string {
    const total = this.totalCount();
    if (total === 0) return 'No routes';
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
    this.onSort({ active: 'routeName', direction: next } as Sort);
  }

  openCreate(): void {
    this.openFormDialog(RouteMasterFormComponent, '460px', null);
  }

  openEdit(route: RouteMaster): void {
    this.openFormDialog(RouteMasterFormComponent, '460px', route);
  }

  openShops(route: RouteMaster): void {
    this.dialog.open(RouteShopsComponent, { width: '440px', maxWidth: '95vw', data: route });
  }
}
