import { Component, OnInit, computed, inject, signal } from '@angular/core';
import { DatePipe, DecimalPipe } from '@angular/common';
import { FormArray, FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { MatCardModule } from '@angular/material/card';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';
import { MatAutocompleteModule, MatAutocompleteSelectedEvent } from '@angular/material/autocomplete';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatDatepickerModule } from '@angular/material/datepicker';
import { MatNativeDateModule } from '@angular/material/core';
import { MatTableModule } from '@angular/material/table';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatTooltipModule } from '@angular/material/tooltip';
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
  imports: [
    ReactiveFormsModule,
    DatePipe,
    DecimalPipe,
    MatCardModule,
    MatFormFieldModule,
    MatInputModule,
    MatSelectModule,
    MatAutocompleteModule,
    MatButtonModule,
    MatIconModule,
    MatDatepickerModule,
    MatNativeDateModule,
    MatTableModule,
    MatProgressSpinnerModule,
    MatTooltipModule
  ],
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

  readonly displayedColumns = ['fruit', 'quantity', 'unitPrice', 'amount', 'remove'];

  readonly form = this.fb.nonNullable.group({
    returnDate: [new Date(), Validators.required],
    supplierID: this.fb.control<number | null>(null, Validators.required),
    supplierSearch: this.fb.nonNullable.control<string>(''),
    purchaseID: this.fb.control<number | null>(null),
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
            returnDate: new Date(supplierReturn.returnDate),
            supplierID: supplierReturn.supplierID,
            supplierSearch: this.supplierNameById(supplierReturn.supplierID),
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

  supplierNameById(supplierID: number | null): string {
    return this.suppliers().find((s) => s.supplierID === supplierID)?.supplierName ?? '';
  }

  filteredSuppliers(search: string | null | undefined): SupplierMaster[] {
    const term = (search ?? '').trim().toLowerCase();
    if (!term) return this.suppliers();
    return this.suppliers().filter((s) => s.supplierName.toLowerCase().includes(term));
  }

  onSupplierSelected(event: MatAutocompleteSelectedEvent): void {
    const supplierID = event.option.value as number;
    this.form.patchValue({ supplierID, supplierSearch: this.supplierNameById(supplierID) });
    this.onSupplierChange();
  }

  onSupplierSearchFocus(): void {
    if (this.form.controls.supplierSearch.value === this.supplierNameById(this.form.controls.supplierID.value)) {
      this.form.controls.supplierSearch.setValue('');
    }
  }

  // Typing away from the settled supplier name must invalidate the stale supplierID -
  // otherwise the form stays "valid" with the old supplier while the field shows
  // different text, and save() would silently post against the wrong supplier. The
  // "against invoice" list belongs to that stale supplier too, so it's cleared here.
  onSupplierSearchInput(): void {
    this.form.controls.supplierID.setValue(null);
    this.form.controls.purchaseID.setValue(null);
    this.supplierPurchases.set([]);
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
      fruitSearch: this.fb.nonNullable.control<string>(fruitID != null ? this.fruitName(fruitID) : ''),
      quantity: [quantity, [Validators.required, Validators.min(0.001)]],
      unitPrice: [unitPrice, [Validators.required, Validators.min(0.01)]],
      boxCount: this.fb.control<number | null>(boxCount, Validators.min(0.01))
    });
  }

  fruitTracksByBox(fruitID: number | null): boolean {
    return this.fruits().find((f) => f.fruitID === fruitID)?.tracksByBox ?? false;
  }

  fruitBoxWeight(fruitID: number | null): number | null {
    return this.fruits().find((f) => f.fruitID === fruitID)?.boxWeightKg ?? null;
  }

  fruitName(fruitID: number | null): string {
    return this.fruits().find((f) => f.fruitID === fruitID)?.fruitName ?? '';
  }

  filteredFruits(search: string | null | undefined): FruitMaster[] {
    const term = (search ?? '').trim().toLowerCase();
    if (!term) return this.fruits();
    return this.fruits().filter((f) => f.fruitName.toLowerCase().includes(term));
  }

  onFruitSelected(index: number, event: MatAutocompleteSelectedEvent): void {
    const fruitID = event.option.value as number;
    this.itemsArray.at(index).patchValue({
      fruitID,
      fruitSearch: this.fruitName(fruitID),
      boxCount: null
    });
  }

  onFruitSearchFocus(index: number): void {
    const item = this.itemsArray.at(index);
    if (item.value.fruitSearch === this.fruitName(item.value.fruitID)) item.patchValue({ fruitSearch: '' });
  }

  // Same as onSupplierSearchInput: editing a row's fruit text must invalidate that
  // row's stale fruitID so save() can't silently post against the wrong fruit.
  onFruitSearchInput(index: number): void {
    this.itemsArray.at(index).patchValue({ fruitID: null });
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
      returnDate: toIso(raw.returnDate as unknown as Date),
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
        this.notification.success(id ? 'Supplier return updated successfully.' : 'Supplier return saved successfully.');
        this.router.navigate(['/supplier-returns']);
      }
    });
  }

  cancel(): void {
    this.router.navigate(['/supplier-returns']);
  }
}
