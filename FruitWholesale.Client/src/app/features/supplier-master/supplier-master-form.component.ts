import { Component, inject } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { MatDialogModule, MAT_DIALOG_DATA, MatDialogRef } from '@angular/material/dialog';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatButtonModule } from '@angular/material/button';
import { SupplierMaster } from '../../core/models/master-data.model';

@Component({
  selector: 'app-supplier-master-form',
  standalone: true,
  imports: [ReactiveFormsModule, MatDialogModule, MatFormFieldModule, MatInputModule, MatButtonModule],
  templateUrl: './supplier-master-form.component.html'
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

  save(): void {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }
    this.dialogRef.close(this.form.getRawValue());
  }
}
