import { Component, OnInit, computed, inject, signal } from '@angular/core';
import { DatePipe, DecimalPipe } from '@angular/common';
import { FormArray, FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { finalize, forkJoin } from 'rxjs';
import { SupplierReturnService } from './supplier-return.service';
import { SupplierMasterService } from '../supplier-master/supplier-master.service';
import { FruitMasterService } from '../fruit-master/fruit-master.service';
import { PurchaseService } from '../purchase/purchase.service';
import { SupplierMaster, FruitMaster } from '../../core/models/master-data.model';
import { PurchaseListItem } from '../../core/models/transactions.model';
import { NotificationService } from '../../core/services/notification.service';
import { toIso } from '../../core/utils/date.util';

@Component({
  selector: 'app-supplier-return-form',
  standalone: true,
  imports: [ReactiveFormsModule, DatePipe, DecimalPipe, MatIconModule, MatProgressSpinnerModule],
  templateUrl: './supplier-return-form.component.html',
  styleUrl: './supplier-return-form.component.scss'
})
export class SupplierReturnFormComponent implements OnInit {
  private readonly fb = inject(FormBuilder);
  private readonly supplierReturnService = inject(SupplierReturnService);
  private readonly supplierService = inject(SupplierMasterService);
  private readonly fruitService = inject(FruitMasterService);
  private readonly purchaseService = inject(PurchaseService);
  private readonly notification = inject(NotificationService);
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);

  readonly loading = signal(true);
  readonly saving = signal(false);
  readonly loadingInvoiceItems = signal(false);
  readonly suppliers = signal<SupplierMaster[]>([]);
  readonly fruits = signal<FruitMaster[]>([]);
  readonly supplierPurchases = signal<PurchaseListItem[]>([]);
  readonly supplierReturnId = signal<number | null>(null);
  readonly isEdit = computed(() => this.supplierReturnId() !== null);

  readonly form = this.fb.nonNullable.group({
    returnDate: [toIso(new Date()), Validators.required],
    supplierID: this.fb.control<number | null>(null, Validators.required),
    purchaseID: this.fb.control<number | null>(null),
    referenceNo: ['', [Validators.required, Validators.maxLength(50)]],
    remarks: [''],
    items: this.fb.array<ReturnType<typeof this.buildItem>>([])
  });

  get itemsArray(): FormArray {
    return this.form.controls.items;
  }

  // Plain methods, not computed() - the FormControl/FormArray values they read
  // are RxJS-based, not signals, so a computed() here would memoize once on
  // first read and never re-run as the form changes.
  selectedSupplier(): SupplierMaster | null {
    const id = this.form.controls.supplierID.value;
    return this.suppliers().find((s) => s.supplierID === id) ?? null;
  }

  balanceAfter(): number {
    const supplier = this.selectedSupplier();
    return supplier ? supplier.currentOutstanding - this.total() : 0;
  }

  ngOnInit(): void {
    const idParam = this.route.snapshot.paramMap.get('id');
    const id = idParam ? Number(idParam) : null;
    this.supplierReturnId.set(id);

    forkJoin({
      suppliers: this.supplierService.getAllActive(),
      fruits: this.fruitService.getAllActive()
    }).subscribe(({ suppliers, fruits }) => {
      this.suppliers.set(suppliers);
      this.fruits.set(fruits);

      if (id) {
        this.supplierReturnService.getById(id).subscribe((supplierReturn) => {
          this.form.patchValue({
            returnDate: supplierReturn.returnDate.slice(0, 10),
            supplierID: supplierReturn.supplierID,
            purchaseID: supplierReturn.purchaseID ?? null,
            referenceNo: supplierReturn.referenceNo,
            remarks: supplierReturn.remarks
          });
          if (supplierReturn.supplierID) this.loadSupplierPurchases(supplierReturn.supplierID);
          supplierReturn.items.forEach((item) =>
            this.itemsArray.push(this.buildItem(item.fruitID, item.quantity, item.unitPrice, item.boxCount ?? null))
          );
          this.loading.set(false);
        });
      } else {
        this.itemsArray.push(this.buildItem());
        this.supplierReturnService.getNextReferenceNo().subscribe((referenceNo) => this.form.controls.referenceNo.setValue(referenceNo));
        this.loading.set(false);
      }
    });
  }

  onSupplierChange(): void {
    this.form.controls.purchaseID.setValue(null);
    this.supplierPurchases.set([]);
    const supplierId = this.form.controls.supplierID.value;
    if (supplierId) this.loadSupplierPurchases(supplierId);
  }

  private loadSupplierPurchases(supplierId: number): void {
    this.purchaseService.getPaged({ pageNumber: 1, pageSize: 50, searchTerm: '' }, supplierId).subscribe((result) => {
      this.supplierPurchases.set(result.items);
    });
  }

  loadItemsFromInvoice(): void {
    const purchaseId = this.form.controls.purchaseID.value;
    if (!purchaseId) return;

    this.loadingInvoiceItems.set(true);
    this.purchaseService.getById(purchaseId).subscribe({
      next: (purchase) => {
        this.itemsArray.clear();
        purchase.items.forEach((item) =>
          this.itemsArray.push(this.buildItem(item.fruitID, item.quantity, item.purchasePrice, item.boxCount ?? null))
        );
        this.loadingInvoiceItems.set(false);
        this.notification.info('Items loaded from invoice — adjust quantities to what is actually being returned.');
      },
      error: () => this.loadingInvoiceItems.set(false)
    });
  }

  buildItem(fruitID: number | null = null, quantity = 0, unitPrice = 0, boxCount: number | null = null) {
    return this.fb.nonNullable.group({
      fruitID: this.fb.control<number | null>(fruitID, Validators.required),
      quantity: [quantity, [Validators.required, Validators.min(0.001)]],
      unitPrice: [unitPrice, [Validators.required, Validators.min(0.01)]],
      boxCount: this.fb.control<number | null>(boxCount, Validators.min(0.01))
    });
  }

  onFruitChange(index: number): void {
    this.itemsArray.at(index).patchValue({ boxCount: null });
  }

  fruitTracksByBox(fruitID: number | null): boolean {
    return this.fruits().find((f) => f.fruitID === fruitID)?.tracksByBox ?? false;
  }

  fruitBoxWeight(fruitID: number | null): number | null {
    return this.fruits().find((f) => f.fruitID === fruitID)?.boxWeightKg ?? null;
  }

  onBoxCountChange(index: number): void {
    const item = this.itemsArray.at(index);
    const boxWeight = this.fruitBoxWeight(item.value.fruitID);
    const boxCount = item.value.boxCount;
    if (boxWeight != null && boxCount != null && boxCount > 0) {
      item.patchValue({ quantity: Math.round(boxWeight * boxCount * 1000) / 1000 });
    }
  }

  addRow(): void {
    this.itemsArray.push(this.buildItem());
  }

  removeRow(index: number): void {
    if (this.itemsArray.length === 1) {
      this.notification.info('At least one item row is required.');
      return;
    }
    this.itemsArray.removeAt(index);
  }

  rowAmount(index: number): number {
    const item = this.itemsArray.at(index).getRawValue();
    if (this.fruitTracksByBox(item.fruitID) && item.boxCount) {
      return item.boxCount * (item.unitPrice || 0);
    }
    return (item.quantity || 0) * (item.unitPrice || 0);
  }

  total(): number {
    return this.itemsArray.controls.reduce((sum, _, i) => sum + this.rowAmount(i), 0);
  }

  save(): void {
    if (this.form.invalid || this.itemsArray.length === 0) {
      this.form.markAllAsTouched();
      this.notification.error('Please fill all required fields correctly.');
      return;
    }

    const raw = this.form.getRawValue();
    const payload = {
      returnDate: raw.returnDate,
      supplierID: raw.supplierID,
      purchaseID: raw.purchaseID,
      referenceNo: raw.referenceNo,
      remarks: raw.remarks,
      items: raw.items.map((i) => ({
        fruitID: i.fruitID,
        quantity: i.quantity,
        unitPrice: i.unitPrice,
        boxCount: this.fruitTracksByBox(i.fruitID) ? i.boxCount : null
      }))
    };

    this.saving.set(true);
    const id = this.supplierReturnId();
    const request$ = id ? this.supplierReturnService.update(id, payload) : this.supplierReturnService.create(payload);

    request$.pipe(finalize(() => this.saving.set(false))).subscribe({
      next: () => {
        this.notification.success(id ? 'Purchase return updated successfully.' : 'Purchase return saved successfully.');
        this.router.navigate(['/supplier-returns']);
      }
    });
  }

  cancel(): void {
    this.router.navigate(['/supplier-returns']);
  }
}
