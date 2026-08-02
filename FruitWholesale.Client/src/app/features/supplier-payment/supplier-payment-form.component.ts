import { Component, OnInit, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { MatDialogModule, MAT_DIALOG_DATA, MatDialogRef } from '@angular/material/dialog';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';
import { MatButtonModule } from '@angular/material/button';
import { MatDatepickerModule } from '@angular/material/datepicker';
import { MatNativeDateModule } from '@angular/material/core';
import { SupplierMasterService } from '../supplier-master/supplier-master.service';
import { SupplierMaster } from '../../core/models/master-data.model';
import { SupplierPayment } from '../../core/models/transactions.model';
import { PAYMENT_MODES } from '../../core/models/common.model';
import { toIso } from '../../core/utils/date.util';

@Component({
  selector: 'app-supplier-payment-form',
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
  templateUrl: './supplier-payment-form.component.html'
})
export class SupplierPaymentFormComponent implements OnInit {
  private readonly fb = inject(FormBuilder);
  private readonly supplierService = inject(SupplierMasterService);
  readonly dialogRef = inject(MatDialogRef<SupplierPaymentFormComponent>);
  readonly data = inject<SupplierPayment | null>(MAT_DIALOG_DATA);

  readonly paymentModes = PAYMENT_MODES;
  readonly suppliers = signal<SupplierMaster[]>([]);

  readonly form = this.fb.nonNullable.group({
    paymentDate: [this.data ? new Date(this.data.paymentDate) : new Date(), Validators.required],
    supplierID: this.fb.control<number | null>(this.data?.supplierID ?? null, Validators.required),
    amountPaid: [this.data?.amountPaid ?? 0, [Validators.required, Validators.min(0.01)]],
    discountAmount: [this.data?.discountAmount ?? 0, [Validators.min(0)]],
    paymentMode: [this.data?.paymentMode ?? 'Cash', Validators.required],
    referenceNumber: [this.data?.referenceNumber ?? ''],
    remarks: [this.data?.remarks ?? '']
  });

  ngOnInit(): void {
    this.supplierService.getAllActive().subscribe((suppliers) => this.suppliers.set(suppliers));
  }

  save(): void {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }
    const raw = this.form.getRawValue();
    this.dialogRef.close({
      ...raw,
      paymentDate: toIso(raw.paymentDate as unknown as Date)
    });
  }
}
