import { Component, OnInit, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { MatDialogModule, MAT_DIALOG_DATA, MatDialogRef } from '@angular/material/dialog';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';
import { MatButtonModule } from '@angular/material/button';
import { RouteMasterService } from '../route-master/route-master.service';
import { RouteMaster, ShopMaster } from '../../core/models/master-data.model';

@Component({
  selector: 'app-shop-master-form',
  standalone: true,
  imports: [ReactiveFormsModule, MatDialogModule, MatFormFieldModule, MatInputModule, MatSelectModule, MatButtonModule],
  templateUrl: './shop-master-form.component.html'
})
export class ShopMasterFormComponent implements OnInit {
  private readonly fb = inject(FormBuilder);
  private readonly routeService = inject(RouteMasterService);
  readonly dialogRef = inject(MatDialogRef<ShopMasterFormComponent>);
  readonly data = inject<ShopMaster | null>(MAT_DIALOG_DATA);
  readonly isEdit = !!this.data;

  readonly routes = signal<RouteMaster[]>([]);

  readonly form = this.fb.nonNullable.group({
    shopName: [this.data?.shopName ?? '', [Validators.required, Validators.maxLength(200)]],
    ownerName: [this.data?.ownerName ?? ''],
    phone: [this.data?.phone ?? '', [Validators.maxLength(20)]],
    address: [this.data?.address ?? ''],
    openingBalance: [{ value: this.data?.openingBalance ?? 0, disabled: this.isEdit }, [Validators.min(0)]],
    creditLimit: [this.data?.creditLimit ?? 0, [Validators.min(0)]],
    routeID: this.fb.control<number | null>(this.data?.routeID ?? null)
  });

  ngOnInit(): void {
    this.routeService.getAllActive().subscribe((routes) => this.routes.set(routes));
  }

  save(): void {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }
    this.dialogRef.close(this.form.getRawValue());
  }
}
