import { Component, OnInit, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { MatDialogModule, MAT_DIALOG_DATA, MatDialogRef } from '@angular/material/dialog';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';
import { MatButtonModule } from '@angular/material/button';
import { MatDatepickerModule } from '@angular/material/datepicker';
import { MatNativeDateModule } from '@angular/material/core';
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
    MatButtonModule,
    MatDatepickerModule,
    MatNativeDateModule
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
    amountReceived: [this.data?.amountReceived ?? 0, [Validators.required, Validators.min(0.01)]],
    discountAmount: [this.data?.discountAmount ?? 0, [Validators.min(0)]],
    paymentMode: [this.data?.paymentMode ?? 'Cash', Validators.required],
    referenceNumber: [this.data?.referenceNumber ?? ''],
    remarks: [this.data?.remarks ?? '']
  });

  ngOnInit(): void {
    this.shopService.getAllActive().subscribe((shops) => this.shops.set(shops));
  }

  save(): void {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }
    const raw = this.form.getRawValue();
    this.dialogRef.close({
      ...raw,
      collectionDate: toIso(raw.collectionDate as unknown as Date)
    });
  }
}
