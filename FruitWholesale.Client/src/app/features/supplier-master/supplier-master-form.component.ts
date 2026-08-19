import { Component, inject } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { MatDialogModule, MAT_DIALOG_DATA, MatDialogRef } from '@angular/material/dialog';
import { MatIconModule } from '@angular/material/icon';
import { SupplierMaster } from '../../core/models/master-data.model';

@Component({
  selector: 'app-supplier-master-form',
  standalone: true,
  imports: [ReactiveFormsModule, MatDialogModule, MatIconModule],
  templateUrl: './supplier-master-form.component.html',
  styleUrl: './supplier-master-form.component.scss'
})
export class SupplierMasterFormComponent {
  private readonly fb = inject(FormBuilder);
  readonly dialogRef = inject(MatDialogRef<SupplierMasterFormComponent>);
  readonly data = inject<SupplierMaster | null>(MAT_DIALOG_DATA);
  readonly isEdit = !!this.data;

  readonly form = this.fb.nonNullable.group({
    supplierName: [this.data?.supplierName ?? '', [Validators.required, Validators.maxLength(200)]],
    phone: [this.data?.phone ?? '', [Validators.maxLength(20)]],
    address: [this.data?.address ?? ''],
    openingBalance: [{ value: this.data?.openingBalance ?? 0, disabled: this.isEdit }, [Validators.min(0)]]
  });

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
