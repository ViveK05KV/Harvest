import { Component, OnInit, computed, inject, signal } from '@angular/core';
import { DatePipe, DecimalPipe } from '@angular/common';
import { FormArray, FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { MatCardModule } from '@angular/material/card';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatDatepickerModule } from '@angular/material/datepicker';
import { MatNativeDateModule } from '@angular/material/core';
import { MatTableModule } from '@angular/material/table';
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
  imports: [
    ReactiveFormsModule,
    DatePipe,
    DecimalPipe,
    MatCardModule,
    MatFormFieldModule,
    MatInputModule,
    MatSelectModule,
    MatButtonModule,
    MatIconModule,
    MatDatepickerModule,
    MatNativeDateModule,
    MatTableModule,
    MatProgressSpinnerModule
  ],
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

  readonly displayedColumns = ['fruit', 'quantity', 'unitPrice', 'amount', 'remove'];

  readonly form = this.fb.nonNullable.group({
    returnDate: [new Date(), Validators.required],
    shopID: this.fb.control<number | null>(null, Validators.required),
    supplyID: this.fb.control<number | null>(null),
    referenceNo: ['', [Validators.required, Validators.maxLength(50)]],
    remarks: [''],
    items: this.fb.array<ReturnType<typeof this.buildItem>>([])
  });

  get itemsArray(): FormArray {
    return this.form.controls.items;
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
            returnDate: new Date(shopReturn.returnDate),
            shopID: shopReturn.shopID,
            supplyID: shopReturn.supplyID ?? null,
            referenceNo: shopReturn.referenceNo,
            remarks: shopReturn.remarks
          });
          if (shopReturn.shopID) this.loadShopSupplies(shopReturn.shopID);
          shopReturn.items.forEach((item) =>
            this.itemsArray.push(this.buildItem(item.fruitID, item.quantity, item.unitPrice))
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
    const shopId = this.form.controls.shopID.value;
    if (shopId) this.loadShopSupplies(shopId);
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
        supply.items.forEach((item) => this.itemsArray.push(this.buildItem(item.fruitID, item.quantity, item.unitPrice)));
        this.loadingInvoiceItems.set(false);
        this.notification.info('Items loaded from invoice — adjust quantities to what is actually being returned.');
      },
      error: () => this.loadingInvoiceItems.set(false)
    });
  }

  buildItem(fruitID: number | null = null, quantity = 0, unitPrice = 0) {
    return this.fb.nonNullable.group({
      fruitID: this.fb.control<number | null>(fruitID, Validators.required),
      quantity: [quantity, [Validators.required, Validators.min(0.001)]],
      unitPrice: [unitPrice, [Validators.required, Validators.min(0.01)]]
    });
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
      returnDate: toIso(raw.returnDate as unknown as Date),
      shopID: raw.shopID,
      supplyID: raw.supplyID,
      referenceNo: raw.referenceNo,
      remarks: raw.remarks,
      items: raw.items.map((i) => ({ fruitID: i.fruitID, quantity: i.quantity, unitPrice: i.unitPrice }))
    };

    this.saving.set(true);
    const id = this.shopReturnId();
    const request$ = id ? this.shopReturnService.update(id, payload) : this.shopReturnService.create(payload);

    request$.pipe(finalize(() => this.saving.set(false))).subscribe({
      next: () => {
        this.notification.success(id ? 'Shop return updated successfully.' : 'Shop return saved successfully.');
        this.router.navigate(['/shop-returns']);
      }
    });
  }

  cancel(): void {
    this.router.navigate(['/shop-returns']);
  }
}
