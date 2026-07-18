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
import { SupplyService } from './supply.service';
import { ShopMasterService } from '../shop-master/shop-master.service';
import { FruitMasterService } from '../fruit-master/fruit-master.service';
import { ShopMaster, FruitMaster } from '../../core/models/master-data.model';
import { NotificationService } from '../../core/services/notification.service';

@Component({
  selector: 'app-supply-form',
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
  templateUrl: './supply-form.component.html',
  styleUrl: './supply-form.component.scss'
})
export class SupplyFormComponent implements OnInit {
  private readonly fb = inject(FormBuilder);
  private readonly supplyService = inject(SupplyService);
  private readonly shopService = inject(ShopMasterService);
  private readonly fruitService = inject(FruitMasterService);
  private readonly notification = inject(NotificationService);
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);

  readonly loading = signal(true);
  readonly saving = signal(false);
  readonly shops = signal<ShopMaster[]>([]);
  readonly fruits = signal<FruitMaster[]>([]);
  readonly supplyId = signal<number | null>(null);
  readonly isEdit = computed(() => this.supplyId() !== null);

  readonly displayedColumns = ['fruit', 'quantity', 'unitPrice', 'amount', 'remove'];

  readonly form = this.fb.nonNullable.group({
    supplyDate: [new Date(), Validators.required],
    shopID: this.fb.control<number | null>(null, Validators.required),
    invoiceNo: ['', [Validators.required, Validators.maxLength(50)]],
    remarks: [''],
    items: this.fb.array<ReturnType<typeof this.buildItem>>([])
  });

  get itemsArray(): FormArray {
    return this.form.controls.items;
  }

  ngOnInit(): void {
    const idParam = this.route.snapshot.paramMap.get('id');
    const id = idParam ? Number(idParam) : null;
    this.supplyId.set(id);

    forkJoin({
      shops: this.shopService.getAllActive(),
      fruits: this.fruitService.getAllActive()
    }).subscribe(({ shops, fruits }) => {
      this.shops.set(shops);
      this.fruits.set(fruits);

      if (id) {
        this.supplyService.getById(id).subscribe((supply) => {
          this.form.patchValue({
            supplyDate: new Date(supply.supplyDate),
            shopID: supply.shopID,
            invoiceNo: supply.invoiceNo,
            remarks: supply.remarks
          });
          supply.items.forEach((item) =>
            this.itemsArray.push(this.buildItem(item.fruitID, item.quantity, item.unitPrice))
          );
          this.loading.set(false);
        });
      } else {
        this.itemsArray.push(this.buildItem());
        this.supplyService.getNextInvoiceNo().subscribe((invoiceNo) => this.form.controls.invoiceNo.setValue(invoiceNo));
        this.loading.set(false);
      }
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

  fruitName(fruitID: number | null): string {
    return this.fruits().find((f) => f.fruitID === fruitID)?.fruitName ?? '';
  }

  fruitUnit(fruitID: number | null): string {
    return this.fruits().find((f) => f.fruitID === fruitID)?.unit ?? '';
  }

  shopName(): string {
    return this.shops().find((s) => s.shopID === this.form.controls.shopID.value)?.shopName ?? '';
  }

  save(): void {
    if (this.form.invalid || this.itemsArray.length === 0) {
      this.form.markAllAsTouched();
      this.notification.error('Please fill all required fields correctly.');
      return;
    }

    const raw = this.form.getRawValue();
    const payload = {
      supplyDate: (raw.supplyDate as unknown as Date).toISOString().slice(0, 10),
      shopID: raw.shopID,
      invoiceNo: raw.invoiceNo,
      remarks: raw.remarks,
      items: raw.items.map((i) => ({ fruitID: i.fruitID, quantity: i.quantity, unitPrice: i.unitPrice }))
    };

    this.saving.set(true);
    const id = this.supplyId();
    const request$ = id ? this.supplyService.update(id, payload) : this.supplyService.create(payload);

    request$.pipe(finalize(() => this.saving.set(false))).subscribe({
      next: () => {
        this.notification.success(id ? 'Supply updated successfully.' : 'Supply saved successfully.');
        this.router.navigate(['/supply']);
      }
    });
  }

  printInvoice(): void {
    window.print();
  }

  cancel(): void {
    this.router.navigate(['/supply']);
  }
}
