import { CurrencyPipe } from '@angular/common';
import { Component, inject } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { MatButtonModule } from '@angular/material/button';
import { MatDatepickerModule } from '@angular/material/datepicker';
import { MatDialogModule, MatDialogRef } from '@angular/material/dialog';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatAutocompleteModule, MatAutocompleteSelectedEvent } from '@angular/material/autocomplete';
import { MatNativeDateModule } from '@angular/material/core';
import { ShopMasterService } from '../shop-master/shop-master.service';
import { ShopMaster } from '../../core/models/master-data.model';
import { CollectionService } from './collection.service';
import { toIso } from '../../core/utils/date.util';
import { signal } from '@angular/core';

@Component({
  selector: 'app-settle-collections-dialog',
  standalone: true,
  imports: [
    CurrencyPipe,
    ReactiveFormsModule,
    MatDialogModule,
    MatFormFieldModule,
    MatInputModule,
    MatAutocompleteModule,
    MatButtonModule,
    MatDatepickerModule,
    MatNativeDateModule
  ],
  template: `
    <h2 mat-dialog-title>Settle Temporary Deposits</h2>
    <form [formGroup]="form" (ngSubmit)="submit()">
      <mat-dialog-content>
        <mat-form-field class="full-width">
          <mat-label>Shop</mat-label>
          <input
            matInput
            formControlName="shopSearch"
            [matAutocomplete]="shopAuto"
            (input)="onShopSearchInput()"
            (blur)="onShopSearchBlur()"
          />
          <mat-autocomplete #shopAuto="matAutocomplete" (optionSelected)="onShopSelected($event)">
            @for (shop of filteredShops(form.value.shopSearch); track shop.shopID) {
              <mat-option [value]="shop.shopID">{{ shop.shopName }}</mat-option>
            }
          </mat-autocomplete>
        </mat-form-field>

        <mat-form-field class="full-width">
          <mat-label>Settlement Date</mat-label>
          <input matInput [matDatepicker]="picker" formControlName="settlementDate" />
          <mat-datepicker-toggle matSuffix [for]="picker"></mat-datepicker-toggle>
          <mat-datepicker #picker></mat-datepicker>
        </mat-form-field>

        @if (previewData(); as preview) {
          <div style="padding: 8px 0; color: #4a148c;">
            <div><strong>{{ preview.shopName }}</strong></div>
            <div>Pending rows: {{ preview.pendingCount }}</div>
            <div>Total pending: {{ preview.pendingTotal | currency:'INR':'symbol':'1.2-2' }}</div>
            <div style="margin-top: 8px;">Cash was already received daily, so no additional cash is booked. This creates one credit on the shop ledger.</div>
          </div>
        }
      </mat-dialog-content>
      <mat-dialog-actions align="end">
        <button mat-button type="button" mat-dialog-close>Cancel</button>
        <button mat-stroked-button color="primary" type="button" (click)="preview()">Preview</button>
        <button mat-flat-button color="primary" type="submit" [disabled]="!previewData()">Confirm</button>
      </mat-dialog-actions>
    </form>
  `
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
    shopSearch: this.fb.nonNullable.control<string>(''),
    settlementDate: [new Date(), Validators.required]
  });

  constructor() {
    this.shopService.getAllActive().subscribe((shops) => this.shops.set(shops));
  }

  filteredShops(search: string | null | undefined): ShopMaster[] {
    const term = (search ?? '').trim().toLowerCase();
    if (!term) return this.shops();
    return this.shops().filter((s) => s.shopName.toLowerCase().includes(term));
  }

  onShopSelected(event: MatAutocompleteSelectedEvent): void {
    const shopID = event.option.value as number;
    this.form.patchValue({ shopID, shopSearch: this.shops().find((s) => s.shopID === shopID)?.shopName ?? '' });
    this.previewData.set(null);
  }

  // Typing away from the selected shop must invalidate the stale shopID -
  // otherwise Confirm stays enabled against a preview that no longer matches
  // the visible shop, and submit() would settle deposits for the wrong shop.
  onShopSearchInput(): void {
    this.form.controls.shopID.setValue(null);
    this.previewData.set(null);
  }

  onShopSearchBlur(): void {
    if (this.form.controls.shopID.value === null) {
      this.form.controls.shopSearch.setValue('');
    }
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
      settlementDate: toIso(raw.settlementDate as unknown as Date)
    });
  }
}
