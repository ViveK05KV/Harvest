import { Component, OnInit, inject, signal } from '@angular/core';
import { DatePipe, DecimalPipe } from '@angular/common';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { MatDialogModule, MAT_DIALOG_DATA, MatDialogRef } from '@angular/material/dialog';
import { MatIconModule } from '@angular/material/icon';
import { ShopMasterService } from '../shop-master/shop-master.service';
import { LedgerService } from '../ledgers/ledger.service';
import { ShopMaster } from '../../core/models/master-data.model';
import { Collection } from '../../core/models/transactions.model';
import { ShopLedgerEntry } from '../../core/models/ledger.model';
import { PAYMENT_MODES, PaymentMode } from '../../core/models/common.model';
import { toIso } from '../../core/utils/date.util';

const QUICK_AMOUNTS = [500, 1000, 2000, 5000, 10000];

@Component({
  selector: 'app-collection-form',
  standalone: true,
  imports: [ReactiveFormsModule, DatePipe, DecimalPipe, MatDialogModule, MatIconModule],
  templateUrl: './collection-form.component.html',
  styleUrl: './collection-form.component.scss'
})
export class CollectionFormComponent implements OnInit {
  private readonly fb = inject(FormBuilder);
  private readonly shopService = inject(ShopMasterService);
  private readonly ledgerService = inject(LedgerService);
  readonly dialogRef = inject(MatDialogRef<CollectionFormComponent>);
  readonly data = inject<Collection | null>(MAT_DIALOG_DATA);

  readonly paymentModes = PAYMENT_MODES;
  readonly quickAmounts = QUICK_AMOUNTS;
  readonly shops = signal<ShopMaster[]>([]);
  readonly recentActivity = signal<ShopLedgerEntry[]>([]);

  readonly form = this.fb.nonNullable.group({
    collectionDate: [this.data ? this.data.collectionDate.slice(0, 10) : toIso(new Date()), Validators.required],
    shopID: this.fb.control<number | null>(this.data?.shopID ?? null, Validators.required),
    amountReceived: [this.data?.amountReceived ?? 0, [Validators.required, Validators.min(0.01)]],
    discountAmount: [this.data?.discountAmount ?? 0, [Validators.min(0)]],
    paymentMode: this.fb.nonNullable.control<PaymentMode>(this.data?.paymentMode ?? 'Cash', Validators.required),
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
    if (this.data?.temporaryStatus === 'Settled') {
      this.form.controls.isTemporary.disable();
    }

    this.shopService.getAllActive().subscribe((shops) => this.shops.set(shops));

    if (this.data?.shopID) {
      this.loadRecentActivity(this.data.shopID);
    }
  }

  selectedShop(): ShopMaster | null {
    const id = this.form.controls.shopID.value;
    return this.shops().find((s) => s.shopID === id) ?? null;
  }

  receivingTotal(): number {
    const raw = this.form.getRawValue();
    return (Number(raw.amountReceived) || 0) + (Number(raw.discountAmount) || 0);
  }

  balanceAfter(): number {
    const shop = this.selectedShop();
    return shop ? shop.currentOutstanding - this.receivingTotal() : 0;
  }

  onShopChange(value: string): void {
    const shopID = value ? Number(value) : null;
    this.form.controls.shopID.setValue(shopID);
    this.recentActivity.set([]);
    if (shopID) this.loadRecentActivity(shopID);
  }

  private loadRecentActivity(shopId: number): void {
    this.ledgerService.getShopLedger(shopId, { pageNumber: 1, pageSize: 4 }).subscribe({
      next: (result) => this.recentActivity.set(result.items)
    });
  }

  setQuickAmount(amount: number): void {
    this.form.controls.amountReceived.setValue(amount);
  }

  setPaymentMode(mode: PaymentMode): void {
    this.form.controls.paymentMode.setValue(mode);
  }

  toggleTemporary(): void {
    if (this.form.controls.isTemporary.disabled) return;
    this.form.controls.isTemporary.setValue(!this.form.controls.isTemporary.value);
  }

  cancel(): void {
    this.dialogRef.close();
  }

  save(): void {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }
    const { isTemporary, ...raw } = this.form.getRawValue();
    const isTemporaryDeposit = Boolean(isTemporary);
    this.dialogRef.close({
      ...raw,
      collectionType: isTemporaryDeposit ? 'Temporary' : 'Normal',
      temporaryStatus: isTemporaryDeposit ? 'Pending' : 'None'
    });
  }
}
