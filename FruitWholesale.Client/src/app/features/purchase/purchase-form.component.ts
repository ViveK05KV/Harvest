import { Component, OnInit, computed, inject, signal } from '@angular/core';
import { DatePipe, DecimalPipe } from '@angular/common';
import { FormArray, FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { finalize, forkJoin } from 'rxjs';
import { PurchaseService } from './purchase.service';
import { SupplierMasterService } from '../supplier-master/supplier-master.service';
import { FruitMasterService } from '../fruit-master/fruit-master.service';
import { SupplierMaster, FruitMaster } from '../../core/models/master-data.model';
import { NotificationService } from '../../core/services/notification.service';
import { toIso } from '../../core/utils/date.util';

@Component({
  selector: 'app-purchase-form',
  standalone: true,
  imports: [ReactiveFormsModule, DatePipe, DecimalPipe, MatIconModule, MatProgressSpinnerModule],
  templateUrl: './purchase-form.component.html',
  styleUrl: './purchase-form.component.scss'
})
export class PurchaseFormComponent implements OnInit {
  private readonly fb = inject(FormBuilder);
  private readonly purchaseService = inject(PurchaseService);
  private readonly supplierService = inject(SupplierMasterService);
  private readonly fruitService = inject(FruitMasterService);
  private readonly notification = inject(NotificationService);
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);

  readonly loading = signal(true);
  readonly saving = signal(false);
  readonly suppliers = signal<SupplierMaster[]>([]);
  readonly fruits = signal<FruitMaster[]>([]);
  readonly purchaseId = signal<number | null>(null);
  readonly isEdit = computed(() => this.purchaseId() !== null);

  readonly form = this.fb.nonNullable.group({
    purchaseDate: [toIso(new Date()), Validators.required],
    supplierID: this.fb.control<number | null>(null, Validators.required),
    invoiceNo: ['', [Validators.required, Validators.maxLength(50)]],
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
    return supplier ? supplier.currentOutstanding + this.total() : 0;
  }

  ngOnInit(): void {
    const idParam = this.route.snapshot.paramMap.get('id');
    const id = idParam ? Number(idParam) : null;
    this.purchaseId.set(id);

    forkJoin({
      suppliers: this.supplierService.getAllActive(),
      fruits: this.fruitService.getAllActive()
    }).subscribe(({ suppliers, fruits }) => {
      this.suppliers.set(suppliers);
      this.fruits.set(fruits);

      if (id) {
        this.purchaseService.getById(id).subscribe((purchase) => {
          this.form.patchValue({
            purchaseDate: purchase.purchaseDate.slice(0, 10),
            supplierID: purchase.supplierID,
            invoiceNo: purchase.invoiceNo,
            remarks: purchase.remarks
          });
          purchase.items.forEach((item) =>
            this.itemsArray.push(this.buildItem(item.fruitID, item.quantity, item.purchasePrice, item.boxCount ?? null))
          );
          this.loading.set(false);
        });
      } else {
        this.itemsArray.push(this.buildItem());
        this.purchaseService.getNextInvoiceNo().subscribe((invoiceNo) => this.form.controls.invoiceNo.setValue(invoiceNo));
        this.loading.set(false);
      }
    });
  }

  buildItem(fruitID: number | null = null, quantity = 0, purchasePrice = 0, boxCount: number | null = null) {
    return this.fb.nonNullable.group({
      fruitID: this.fb.control<number | null>(fruitID, Validators.required),
      quantity: [quantity, [Validators.required, Validators.min(0.001)]],
      purchasePrice: [purchasePrice, [Validators.required, Validators.min(0.01)]],
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
      return item.boxCount * (item.purchasePrice || 0);
    }
    return (item.quantity || 0) * (item.purchasePrice || 0);
  }

  total(): number {
    return this.itemsArray.controls.reduce((sum, _, i) => sum + this.rowAmount(i), 0);
  }

  fruitName(fruitID: number | null): string {
    return this.fruits().find((f) => f.fruitID === fruitID)?.fruitName ?? '';
  }

  fruitUnit(fruitID: number | null): string {
    return this.fruits().find((f) => f.fruitID === fruitID)?.unit ?? '';
  }

  save(): void {
    if (this.form.invalid || this.itemsArray.length === 0) {
      this.form.markAllAsTouched();
      this.notification.error('Please fill all required fields correctly.');
      return;
    }

    const raw = this.form.getRawValue();
    const payload = {
      purchaseDate: raw.purchaseDate,
      supplierID: raw.supplierID,
      invoiceNo: raw.invoiceNo,
      remarks: raw.remarks,
      items: raw.items.map((i) => ({
        fruitID: i.fruitID,
        quantity: i.quantity,
        purchasePrice: i.purchasePrice,
        boxCount: this.fruitTracksByBox(i.fruitID) ? i.boxCount : null
      }))
    };

    this.saving.set(true);
    const id = this.purchaseId();
    const request$ = id ? this.purchaseService.update(id, payload) : this.purchaseService.create(payload);

    request$.pipe(finalize(() => this.saving.set(false))).subscribe({
      next: () => {
        this.notification.success(id ? 'Purchase updated successfully.' : 'Purchase saved successfully.');
        this.router.navigate(['/purchase']);
      }
    });
  }

  printInvoice(): void {
    window.print();
  }

  cancel(): void {
    this.router.navigate(['/purchase']);
  }
}
