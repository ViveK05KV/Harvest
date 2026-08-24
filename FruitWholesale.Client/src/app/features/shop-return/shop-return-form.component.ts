import { Component, OnInit, computed, inject, signal } from '@angular/core';
import { DatePipe, DecimalPipe } from '@angular/common';
import { FormArray, FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { finalize, forkJoin } from 'rxjs';
import { ShopReturnService } from './shop-return.service';
import { ShopMasterService } from '../shop-master/shop-master.service';
import { FruitMasterService } from '../fruit-master/fruit-master.service';
import { SupplyService } from '../supply/supply.service';
import { ShopMaster, FruitMaster } from '../../core/models/master-data.model';
import { SupplyListItem } from '../../core/models/transactions.model';
import { NotificationService } from '../../core/services/notification.service';
import { toIso } from '../../core/utils/date.util';

@Component({
  selector: 'app-shop-return-form',
  standalone: true,
  imports: [ReactiveFormsModule, DatePipe, DecimalPipe, MatIconModule, MatProgressSpinnerModule],
  templateUrl: './shop-return-form.component.html',
  styleUrl: './shop-return-form.component.scss'
})
export class ShopReturnFormComponent implements OnInit {
  private readonly fb = inject(FormBuilder);
  private readonly shopReturnService = inject(ShopReturnService);
  private readonly shopService = inject(ShopMasterService);
  private readonly fruitService = inject(FruitMasterService);
  private readonly supplyService = inject(SupplyService);
  private readonly notification = inject(NotificationService);
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);

  readonly loading = signal(true);
  readonly saving = signal(false);
  readonly loadingInvoiceItems = signal(false);
  readonly shops = signal<ShopMaster[]>([]);
  readonly fruits = signal<FruitMaster[]>([]);
  readonly shopSupplies = signal<SupplyListItem[]>([]);
  readonly shopReturnId = signal<number | null>(null);
  readonly isEdit = computed(() => this.shopReturnId() !== null);

  readonly form = this.fb.nonNullable.group({
    returnDate: [toIso(new Date()), Validators.required],
    shopID: this.fb.control<number | null>(null, Validators.required),
    supplyID: this.fb.control<number | null>(null),
    referenceNo: ['', [Validators.required, Validators.maxLength(50)]],
    remarks: [''],
    items: this.fb.array<ReturnType<typeof this.buildItem>>([])
  });

  get itemsArray(): FormArray {
    return this.form.controls.items;
  }

  selectedShop(): ShopMaster | null {
    const id = this.form.controls.shopID.value;
    return this.shops().find((s) => s.shopID === id) ?? null;
  }

  balanceAfter(): number {
    const shop = this.selectedShop();
    return shop ? shop.currentOutstanding - this.total() : 0;
  }

  ngOnInit(): void {
    const idParam = this.route.snapshot.paramMap.get('id');
    const id = idParam ? Number(idParam) : null;
    this.shopReturnId.set(id);

    forkJoin({
      shops: this.shopService.getAllActive(),
      fruits: this.fruitService.getAllActive()
    }).subscribe(({ shops, fruits }) => {
      this.shops.set(shops);
      this.fruits.set(fruits);

      if (id) {
        this.shopReturnService.getById(id).subscribe((shopReturn) => {
          this.form.patchValue({
            returnDate: shopReturn.returnDate.slice(0, 10),
            shopID: shopReturn.shopID,
            supplyID: shopReturn.supplyID ?? null,
            referenceNo: shopReturn.referenceNo,
            remarks: shopReturn.remarks
          });
          if (shopReturn.shopID) this.loadShopSupplies(shopReturn.shopID);
          shopReturn.items.forEach((item) =>
            this.itemsArray.push(this.buildItem(item.fruitID, item.quantity, item.unitPrice, item.boxCount ?? null))
          );
          this.loading.set(false);
        });
      } else {
        this.itemsArray.push(this.buildItem());
        this.shopReturnService.getNextReferenceNo().subscribe((referenceNo) => this.form.controls.referenceNo.setValue(referenceNo));
        this.loading.set(false);
      }
    });
  }

  onShopChange(): void {
    this.form.controls.supplyID.setValue(null);
    this.shopSupplies.set([]);
    const shopID = this.form.controls.shopID.value;
    if (shopID) this.loadShopSupplies(shopID);
  }

  private loadShopSupplies(shopId: number): void {
    this.supplyService.getPaged({ pageNumber: 1, pageSize: 50, searchTerm: '' }, shopId).subscribe((result) => {
      this.shopSupplies.set(result.items);
    });
  }

  loadItemsFromInvoice(): void {
    const supplyId = this.form.controls.supplyID.value;
    if (!supplyId) return;

    this.loadingInvoiceItems.set(true);
    this.supplyService.getById(supplyId).subscribe({
      next: (supply) => {
        this.itemsArray.clear();
        supply.items.forEach((item) =>
          this.itemsArray.push(this.buildItem(item.fruitID, item.quantity, item.unitPrice, item.boxCount ?? null))
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
      saleType: this.fb.nonNullable.control<'kg' | 'box'>(boxCount != null ? 'box' : 'kg'),
      quantity: [quantity, [Validators.required, Validators.min(0.001)]],
      unitPrice: [unitPrice, [Validators.required, Validators.min(0.01)]],
      boxCount: this.fb.control<number | null>(boxCount, Validators.min(0.01))
    });
  }

  onFruitChange(index: number): void {
    this.itemsArray.at(index).patchValue({ saleType: 'kg', boxCount: null });
  }

  fruitTracksByBox(fruitID: number | null): boolean {
    return this.fruits().find((f) => f.fruitID === fruitID)?.tracksByBox ?? false;
  }

  fruitBoxWeight(fruitID: number | null): number | null {
    return this.fruits().find((f) => f.fruitID === fruitID)?.boxWeightKg ?? null;
  }

  fruitUnit(fruitID: number | null): string {
    return this.fruits().find((f) => f.fruitID === fruitID)?.unit ?? '';
  }

  onSaleTypeChange(index: number): void {
    const item = this.itemsArray.at(index);
    if (item.value.saleType === 'kg') {
      item.patchValue({ boxCount: null });
    } else {
      this.recomputeQuantityFromBoxes(index);
    }
  }

  onBoxCountChange(index: number): void {
    this.recomputeQuantityFromBoxes(index);
  }

  private recomputeQuantityFromBoxes(index: number): void {
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
    if (this.fruitTracksByBox(item.fruitID) && item.saleType === 'box') {
      return (item.boxCount || 0) * (item.unitPrice || 0);
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
      shopID: raw.shopID,
      supplyID: raw.supplyID,
      referenceNo: raw.referenceNo,
      remarks: raw.remarks,
      items: raw.items.map((i) => ({
        fruitID: i.fruitID,
        quantity: i.quantity,
        unitPrice: i.unitPrice,
        boxCount: this.fruitTracksByBox(i.fruitID) && i.saleType === 'box' ? i.boxCount : null
      }))
    };

    this.saving.set(true);
    const id = this.shopReturnId();
    const request$ = id ? this.shopReturnService.update(id, payload) : this.shopReturnService.create(payload);

    request$.pipe(finalize(() => this.saving.set(false))).subscribe({
      next: () => {
        this.notification.success(id ? 'Sales return updated successfully.' : 'Sales return saved successfully.');
        this.router.navigate(['/shop-returns']);
      }
    });
  }

  cancel(): void {
    this.router.navigate(['/shop-returns']);
  }
}
