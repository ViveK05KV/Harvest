import { Component, OnInit, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { MatDialogModule, MAT_DIALOG_DATA, MatDialogRef } from '@angular/material/dialog';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';
import { MatAutocompleteModule, MatAutocompleteSelectedEvent } from '@angular/material/autocomplete';
import { MatButtonModule } from '@angular/material/button';
import { MatDatepickerModule } from '@angular/material/datepicker';
import { MatNativeDateModule } from '@angular/material/core';
import { MatCheckboxModule } from '@angular/material/checkbox';
import { ShopMasterService } from '../shop-master/shop-master.service';
import { ShopMaster } from '../../core/models/master-data.model';
import { Collection } from '../../core/models/transactions.model';
import { PAYMENT_MODES } from '../../core/models/common.model';
import { toIso } from '../../core/utils/date.util';

@Component({
  selector: 'app-collection-form',
  standalone: true,
  imports: [
    ReactiveFormsModule,
    MatDialogModule,
    MatFormFieldModule,
    MatInputModule,
    MatSelectModule,
    MatAutocompleteModule,
    MatButtonModule,
    MatDatepickerModule,
    MatNativeDateModule,
    MatCheckboxModule
  ],
  templateUrl: './collection-form.component.html'
})
export class CollectionFormComponent implements OnInit {
  private readonly fb = inject(FormBuilder);
  private readonly shopService = inject(ShopMasterService);
  readonly dialogRef = inject(MatDialogRef<CollectionFormComponent>);
  readonly data = inject<Collection | null>(MAT_DIALOG_DATA);

  readonly paymentModes = PAYMENT_MODES;
  readonly shops = signal<ShopMaster[]>([]);

  readonly form = this.fb.nonNullable.group({
    collectionDate: [this.data ? new Date(this.data.collectionDate) : new Date(), Validators.required],
    shopID: this.fb.control<number | null>(this.data?.shopID ?? null, Validators.required),
    shopSearch: this.fb.nonNullable.control<string>(''),
    amountReceived: [this.data?.amountReceived ?? 0, [Validators.required, Validators.min(0.01)]],
    discountAmount: [this.data?.discountAmount ?? 0, [Validators.min(0)]],
    paymentMode: [this.data?.paymentMode ?? 'Cash', Validators.required],
    isTemporary: [this.getInitialIsTemporary()],
    referenceNumber: [this.data?.referenceNumber ?? ''],
    remarks: [this.data?.remarks ?? '']
  });

  private getInitialIsTemporary(): boolean {
    const collectionType = this.data?.collectionType?.toLowerCase();
    const temporaryStatus = this.data?.temporaryStatus?.toLowerCase();
    return collectionType === 'temporary' || temporaryStatus === 'pending' || temporaryStatus === 'settled';
  }

  ngOnInit(): void {
    this.form.patchValue({ isTemporary: this.getInitialIsTemporary() });

    if (this.data?.temporaryStatus === 'Settled') {
      this.form.controls.isTemporary.disable();
    }

    this.shopService.getAllActive().subscribe((shops) => {
      this.shops.set(shops);
      if (this.data?.shopID) {
        this.form.patchValue({ shopSearch: this.shopNameById(this.data.shopID) });
      }
    });
  }

  shopNameById(shopID: number | null): string {
    return this.shops().find((s) => s.shopID === shopID)?.shopName ?? '';
  }

  readonly displayShop = (value: unknown): string =>
    typeof value === 'number' ? this.shopNameById(value) : typeof value === 'string' ? value : '';

  filteredShops(search: string | null | undefined): ShopMaster[] {
    const term = (search ?? '').trim().toLowerCase();
    if (!term) return this.shops();
    return this.shops().filter((s) => s.shopName.toLowerCase().includes(term));
  }

  onShopSelected(event: MatAutocompleteSelectedEvent): void {
    const shopID = event.option.value as number;
    this.form.patchValue({ shopID, shopSearch: this.shopNameById(shopID) });
  }

  onShopSearchFocus(): void {
    const selectedShopName = this.shopNameById(this.form.controls.shopID.value);
    const currentValue = this.form.controls.shopSearch.value;

    if (selectedShopName && currentValue === selectedShopName) {
      this.form.controls.shopSearch.setValue(selectedShopName);
    }
  }

  // Typing away from the settled shop name must invalidate the stale shopID -
  // otherwise the form stays "valid" with the old shop while the field shows
  // different text, and save() would silently post against the wrong shop.
  onShopSearchInput(): void {
    this.form.controls.shopID.setValue(null);
  }

  save(): void {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }
    const { shopSearch, isTemporary, ...raw } = this.form.getRawValue();
    const isTemporaryDeposit = Boolean(isTemporary);
    this.dialogRef.close({
      ...raw,
      collectionDate: toIso(raw.collectionDate as unknown as Date),
      collectionType: isTemporaryDeposit ? 'Temporary' : 'Normal',
      temporaryStatus: isTemporaryDeposit ? 'Pending' : 'None'
    });
  }
}
