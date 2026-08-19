import { Component, OnInit, inject, signal } from '@angular/core';
import { MatDialogModule, MAT_DIALOG_DATA, MatDialogRef } from '@angular/material/dialog';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatIconModule } from '@angular/material/icon';
import { ShopMasterService } from '../shop-master/shop-master.service';
import { RouteMaster, ShopMaster } from '../../core/models/master-data.model';

@Component({
  selector: 'app-route-shops',
  standalone: true,
  imports: [MatDialogModule, MatProgressSpinnerModule, MatIconModule],
  templateUrl: './route-shops.component.html',
  styleUrl: './route-shops.component.scss'
})
export class RouteShopsComponent implements OnInit {
  private readonly shopService = inject(ShopMasterService);
  private readonly dialogRef = inject(MatDialogRef<RouteShopsComponent>);
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

  close(): void {
    this.dialogRef.close();
  }
}
