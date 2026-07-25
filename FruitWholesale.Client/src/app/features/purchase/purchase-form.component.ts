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
import { PurchaseService } from './purchase.service';
import { SupplierMasterService } from '../supplier-master/supplier-master.service';
import { FruitMasterService } from '../fruit-master/fruit-master.service';
import { SupplierMaster, FruitMaster } from '../../core/models/master-data.model';
import { NotificationService } from '../../core/services/notification.service';

@Component({
  selector: 'app-purchase-form',
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

  readonly displayedColumns = ['fruit', 'quantity', 'purchasePrice', 'amount', 'remove'];

  readonly form = this.fb.nonNullable.group({
    purchaseDate: [new Date(), Validators.required],
    supplierID: this.fb.control<number | null>(null, Validators.required),
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
            purchaseDate: new Date(purchase.purchaseDate),
            supplierID: purchase.supplierID,
            invoiceNo: purchase.invoiceNo,
            remarks: purchase.remarks
          });
          purchase.items.forEach((item) =>
            this.itemsArray.push(this.buildItem(item.fruitID, item.quantity, item.purchasePrice))
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

  buildItem(fruitID: number | null = null, quantity = 0, purchasePrice = 0) {
    return this.fb.nonNullable.group({
      fruitID: this.fb.control<number | null>(fruitID, Validators.required),
      quantity: [quantity, [Validators.required, Validators.min(0.001)]],
      purchasePrice: [purchasePrice, [Validators.required, Validators.min(0.01)]]
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

  supplierName(): string {
    return this.suppliers().find((s) => s.supplierID === this.form.controls.supplierID.value)?.supplierName ?? '';
  }

  save(): void {
    if (this.form.invalid || this.itemsArray.length === 0) {
      this.form.markAllAsTouched();
      this.notification.error('Please fill all required fields correctly.');
      return;
    }

    const raw = this.form.getRawValue();
    const payload = {
      purchaseDate: (raw.purchaseDate as unknown as Date).toISOString().slice(0, 10),
      supplierID: raw.supplierID,
      invoiceNo: raw.invoiceNo,
      remarks: raw.remarks,
      items: raw.items.map((i) => ({ fruitID: i.fruitID, quantity: i.quantity, purchasePrice: i.purchasePrice }))
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
