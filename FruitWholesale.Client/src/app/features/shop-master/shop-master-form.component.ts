import { Component, OnInit, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { MatDialogModule, MAT_DIALOG_DATA, MatDialogRef } from '@angular/material/dialog';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';
import { MatAutocompleteModule, MatAutocompleteSelectedEvent } from '@angular/material/autocomplete';
import { MatButtonModule } from '@angular/material/button';
import { RouteMasterService } from '../route-master/route-master.service';
import { SupplierMasterService } from '../supplier-master/supplier-master.service';
import { RouteMaster, ShopMaster, SupplierMaster } from '../../core/models/master-data.model';

@Component({
  selector: 'app-shop-master-form',
  standalone: true,
  imports: [
    ReactiveFormsModule,
    MatDialogModule,
    MatFormFieldModule,
    MatInputModule,
    MatSelectModule,
    MatAutocompleteModule,
    MatButtonModule
  ],
  templateUrl: './shop-master-form.component.html'
})
export class ShopMasterFormComponent implements OnInit {
  private readonly fb = inject(FormBuilder);
  private readonly routeService = inject(RouteMasterService);
  private readonly supplierService = inject(SupplierMasterService);
  readonly dialogRef = inject(MatDialogRef<ShopMasterFormComponent>);
  readonly data = inject<ShopMaster | null>(MAT_DIALOG_DATA);
  readonly isEdit = !!this.data;

  readonly routes = signal<RouteMaster[]>([]);
  readonly suppliers = signal<SupplierMaster[]>([]);

  readonly form = this.fb.nonNullable.group({
    shopName: [this.data?.shopName ?? '', [Validators.required, Validators.maxLength(200)]],
    ownerName: [this.data?.ownerName ?? ''],
    phone: [this.data?.phone ?? '', [Validators.maxLength(20)]],
    address: [this.data?.address ?? ''],
    openingBalance: [{ value: this.data?.openingBalance ?? 0, disabled: this.isEdit }, [Validators.min(0)]],
    creditLimit: [this.data?.creditLimit ?? 0, [Validators.min(0)]],
    routeID: this.fb.control<number | null>(this.data?.routeID ?? null),
    linkedSupplierID: this.fb.control<number | null>(this.data?.linkedSupplierID ?? null),
    linkedSupplierSearch: this.fb.nonNullable.control<string>('')
  });

  ngOnInit(): void {
    this.routeService.getAllActive().subscribe((routes) => this.routes.set(routes));
    this.supplierService.getAllActive().subscribe((suppliers) => {
      this.suppliers.set(suppliers);
      if (this.data?.linkedSupplierID) {
        this.form.controls.linkedSupplierSearch.setValue(this.supplierNameById(this.data.linkedSupplierID));
      }
    });
  }

  supplierNameById(supplierID: number | null): string {
    return this.suppliers().find((s) => s.supplierID === supplierID)?.supplierName ?? '';
  }

  filteredSuppliers(search: string | null | undefined): SupplierMaster[] {
    const term = (search ?? '').trim().toLowerCase();
    if (!term) return this.suppliers();
    return this.suppliers().filter((s) => s.supplierName.toLowerCase().includes(term));
  }

  onLinkedSupplierSelected(event: MatAutocompleteSelectedEvent): void {
    const linkedSupplierID = event.option.value as number;
    this.form.patchValue({ linkedSupplierID, linkedSupplierSearch: this.supplierNameById(linkedSupplierID) });
  }

  onLinkedSupplierSearchFocus(): void {
    if (this.form.controls.linkedSupplierSearch.value === this.supplierNameById(this.form.controls.linkedSupplierID.value)) {
      this.form.controls.linkedSupplierSearch.setValue('');
    }
  }

  clearLinkedSupplier(): void {
    this.form.patchValue({ linkedSupplierID: null, linkedSupplierSearch: '' });
  }

  // Typing away from the settled supplier name must invalidate the stale
  // linkedSupplierID - otherwise save() would silently keep the old link while
  // the field shows different text.
  onLinkedSupplierSearchInput(): void {
    this.form.controls.linkedSupplierID.setValue(null);
  }

  save(): void {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }
    const { linkedSupplierSearch, ...raw } = this.form.getRawValue();
    this.dialogRef.close(raw);
  }
}
