import { Component, inject } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { MatDialogModule, MAT_DIALOG_DATA, MatDialogRef } from '@angular/material/dialog';
import { MatIconModule } from '@angular/material/icon';
import { SupplierMaster } from '../../core/models/master-data.model';

@Component({
  selector: 'app-supplier-balance-adjustment',
  standalone: true,
  imports: [ReactiveFormsModule, MatDialogModule, MatIconModule],
  templateUrl: './supplier-balance-adjustment.component.html',
  styleUrl: './supplier-balance-adjustment.component.scss'
})
export class SupplierBalanceAdjustmentComponent {
  private readonly fb = inject(FormBuilder);
  readonly dialogRef = inject(MatDialogRef<SupplierBalanceAdjustmentComponent>);
  readonly supplier = inject<SupplierMaster>(MAT_DIALOG_DATA);

  readonly form = this.fb.nonNullable.group({
    isIncrease: [true, Validators.required],
    amount: [0, [Validators.required, Validators.min(0.01)]],
    narration: ['', Validators.required]
  });

  setDirection(isIncrease: boolean): void {
    this.form.controls.isIncrease.setValue(isIncrease);
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
