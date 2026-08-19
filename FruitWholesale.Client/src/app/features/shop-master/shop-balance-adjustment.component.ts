import { Component, inject } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { MatDialogModule, MAT_DIALOG_DATA, MatDialogRef } from '@angular/material/dialog';
import { MatIconModule } from '@angular/material/icon';
import { ShopMaster } from '../../core/models/master-data.model';

@Component({
  selector: 'app-shop-balance-adjustment',
  standalone: true,
  imports: [ReactiveFormsModule, MatDialogModule, MatIconModule],
  templateUrl: './shop-balance-adjustment.component.html',
  styleUrl: './shop-balance-adjustment.component.scss'
})
export class ShopBalanceAdjustmentComponent {
  private readonly fb = inject(FormBuilder);
  readonly dialogRef = inject(MatDialogRef<ShopBalanceAdjustmentComponent>);
  readonly shop = inject<ShopMaster>(MAT_DIALOG_DATA);

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
