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
import { MatChipsModule } from '@angular/material/chips';
import { MasterListBase } from '../../core/base/master-list-base';
import { RouteMasterService } from './route-master.service';
import { RouteMasterFormComponent } from './route-master-form.component';
import { RouteShopsComponent } from './route-shops.component';
import { RouteMaster, SaveRouteMaster } from '../../core/models/master-data.model';

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
  templateUrl: './route-master-list.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class RouteMasterListComponent extends MasterListBase<RouteMaster, SaveRouteMaster> {
  readonly displayedColumns = ['routeName', 'description', 'shopCount', 'isActive', 'actions'];

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

  openCreate(): void {
    this.openFormDialog(RouteMasterFormComponent, '460px', null);
  }

  openEdit(route: RouteMaster): void {
    this.openFormDialog(RouteMasterFormComponent, '460px', route);
  }

  openShops(route: RouteMaster): void {
    this.dialog.open(RouteShopsComponent, { width: '420px', data: route });
  }
}
