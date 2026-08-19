import { Component, OnInit, inject, signal } from '@angular/core';
import { DatePipe, DecimalPipe } from '@angular/common';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { MatDialogModule, MAT_DIALOG_DATA, MatDialogRef } from '@angular/material/dialog';
import { MatIconModule } from '@angular/material/icon';
import { SupplierMasterService } from '../supplier-master/supplier-master.service';
import { LedgerService } from '../ledgers/ledger.service';
import { SupplierMaster } from '../../core/models/master-data.model';
import { SupplierPayment } from '../../core/models/transactions.model';
import { SupplierLedgerEntry } from '../../core/models/ledger.model';
import { PAYMENT_MODES, PaymentMode } from '../../core/models/common.model';
import { toIso } from '../../core/utils/date.util';

const QUICK_AMOUNTS = [500, 1000, 2000, 5000, 10000];

@Component({
  selector: 'app-supplier-payment-form',
  standalone: true,
  imports: [ReactiveFormsModule, DatePipe, DecimalPipe, MatDialogModule, MatIconModule],
  templateUrl: './supplier-payment-form.component.html',
  styleUrl: './supplier-payment-form.component.scss'
})
export class SupplierPaymentFormComponent implements OnInit {
  private readonly fb = inject(FormBuilder);
  private readonly supplierService = inject(SupplierMasterService);
  private readonly ledgerService = inject(LedgerService);
  readonly dialogRef = inject(MatDialogRef<SupplierPaymentFormComponent>);
  readonly data = inject<SupplierPayment | null>(MAT_DIALOG_DATA);

  readonly paymentModes = PAYMENT_MODES;
  readonly quickAmounts = QUICK_AMOUNTS;
  readonly suppliers = signal<SupplierMaster[]>([]);
  readonly recentActivity = signal<SupplierLedgerEntry[]>([]);

  readonly form = this.fb.nonNullable.group({
    paymentDate: [this.data ? this.data.paymentDate.slice(0, 10) : toIso(new Date()), Validators.required],
    supplierID: this.fb.control<number | null>(this.data?.supplierID ?? null, Validators.required),
    amountPaid: [this.data?.amountPaid ?? 0, [Validators.required, Validators.min(0.01)]],
    discountAmount: [this.data?.discountAmount ?? 0, [Validators.min(0)]],
    paymentMode: this.fb.nonNullable.control<PaymentMode>(this.data?.paymentMode ?? 'Cash', Validators.required),
    referenceNumber: [this.data?.referenceNumber ?? ''],
    remarks: [this.data?.remarks ?? '']
  });

  ngOnInit(): void {
    this.supplierService.getAllActive().subscribe((suppliers) => this.suppliers.set(suppliers));

    if (this.data?.supplierID) {
      this.loadRecentActivity(this.data.supplierID);
    }
  }

  selectedSupplier(): SupplierMaster | null {
    const id = this.form.controls.supplierID.value;
    return this.suppliers().find((s) => s.supplierID === id) ?? null;
  }

  payingTotal(): number {
    const raw = this.form.getRawValue();
    return (Number(raw.amountPaid) || 0) + (Number(raw.discountAmount) || 0);
  }

  balanceAfter(): number {
    const supplier = this.selectedSupplier();
    return supplier ? supplier.currentOutstanding - this.payingTotal() : 0;
  }

  onSupplierChange(value: string): void {
    const supplierID = value ? Number(value) : null;
    this.form.controls.supplierID.setValue(supplierID);
    this.recentActivity.set([]);
    if (supplierID) this.loadRecentActivity(supplierID);
  }

  private loadRecentActivity(supplierId: number): void {
    this.ledgerService.getSupplierLedger(supplierId, { pageNumber: 1, pageSize: 4 }).subscribe({
      next: (result) => this.recentActivity.set(result.items)
    });
  }

  setQuickAmount(amount: number): void {
    this.form.controls.amountPaid.setValue(amount);
  }

  setPaymentMode(mode: PaymentMode): void {
    this.form.controls.paymentMode.setValue(mode);
  }

  cancel(): void {
    this.dialogRef.close();
  }

  save(): void {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }
    this.dialogRef.close(this.form.getRawValue());
  }
}
