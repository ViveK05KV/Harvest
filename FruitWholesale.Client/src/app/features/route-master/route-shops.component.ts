import { Component, OnInit, inject, signal } from '@angular/core';
import { MatDialogModule, MAT_DIALOG_DATA } from '@angular/material/dialog';
import { MatListModule } from '@angular/material/list';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatIconModule } from '@angular/material/icon';
import { ShopMasterService } from '../shop-master/shop-master.service';
import { RouteMaster, ShopMaster } from '../../core/models/master-data.model';

@Component({
  selector: 'app-route-shops',
  standalone: true,
  imports: [MatDialogModule, MatListModule, MatProgressSpinnerModule, MatIconModule],
  templateUrl: './route-shops.component.html'
})
export class RouteShopsComponent implements OnInit {
  private readonly shopService = inject(ShopMasterService);
  readonly route = inject<RouteMaster>(MAT_DIALOG_DATA);

  readonly loading = signal(true);
  readonly shops = signal<ShopMaster[]>([]);

  ngOnInit(): void {
    this.shopService.getPaged({ pageNumber: 1, pageSize: 100, searchTerm: '' }, this.route.routeID).subscribe({
      next: (result) => {
        this.shops.set(result.items);
        this.loading.set(false);
      },
      error: () => this.loading.set(false)
    });
  }
}
