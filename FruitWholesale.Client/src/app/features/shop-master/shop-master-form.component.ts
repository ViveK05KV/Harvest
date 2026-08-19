import { Component, OnInit, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { MatDialogModule, MAT_DIALOG_DATA, MatDialogRef } from '@angular/material/dialog';
import { MatIconModule } from '@angular/material/icon';
import { RouteMasterService } from '../route-master/route-master.service';
import { SupplierMasterService } from '../supplier-master/supplier-master.service';
import { RouteMaster, ShopMaster, SupplierMaster } from '../../core/models/master-data.model';

@Component({
  selector: 'app-shop-master-form',
  standalone: true,
  imports: [ReactiveFormsModule, MatDialogModule, MatIconModule],
  templateUrl: './shop-master-form.component.html',
  styleUrl: './shop-master-form.component.scss'
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
    linkedSupplierID: this.fb.control<number | null>(this.data?.linkedSupplierID ?? null)
  });

  ngOnInit(): void {
    this.routeService.getAllActive().subscribe((routes) => this.routes.set(routes));
    this.supplierService.getAllActive().subscribe((suppliers) => this.suppliers.set(suppliers));
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
