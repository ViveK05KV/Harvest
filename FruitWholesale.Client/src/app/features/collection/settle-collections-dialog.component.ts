import { CurrencyPipe } from '@angular/common';
import { Component, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { MatDialogModule, MatDialogRef } from '@angular/material/dialog';
import { MatIconModule } from '@angular/material/icon';
import { ShopMasterService } from '../shop-master/shop-master.service';
import { ShopMaster } from '../../core/models/master-data.model';
import { CollectionService } from './collection.service';
import { toIso } from '../../core/utils/date.util';

@Component({
  selector: 'app-settle-collections-dialog',
  standalone: true,
  imports: [CurrencyPipe, ReactiveFormsModule, MatDialogModule, MatIconModule],
  templateUrl: './settle-collections-dialog.component.html',
  styleUrl: './settle-collections-dialog.component.scss'
})
export class SettleCollectionsDialogComponent {
  private readonly fb = inject(FormBuilder);
  private readonly shopService = inject(ShopMasterService);
  private readonly collectionService = inject(CollectionService);
  readonly dialogRef = inject(MatDialogRef<SettleCollectionsDialogComponent>);
  readonly shops = signal<ShopMaster[]>([]);
  readonly previewData = signal<{ shopID: number; shopName?: string; pendingCount: number; pendingTotal: number } | null>(null);

  readonly form = this.fb.nonNullable.group({
    shopID: this.fb.control<number | null>(null, Validators.required),
    settlementDate: [toIso(new Date()), Validators.required]
  });

  constructor() {
    this.shopService.getAllActive().subscribe((shops) => this.shops.set(shops));
  }

  onShopChange(): void {
    this.previewData.set(null);
  }

  preview(): void {
    if (this.form.invalid) return;
    const shopID = this.form.controls.shopID.value;
    if (!shopID) return;
    this.collectionService.getPendingSettlementPreview(shopID).subscribe((preview) => this.previewData.set(preview));
  }

  submit(): void {
    if (this.form.invalid || !this.previewData()) return;
    const raw = this.form.getRawValue();
    this.dialogRef.close({
      shopID: raw.shopID,
      settlementDate: raw.settlementDate
    });
  }

  cancel(): void {
    this.dialogRef.close();
  }
}
