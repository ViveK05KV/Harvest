import { Component, inject } from '@angular/core';
import { DecimalPipe } from '@angular/common';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { MAT_DIALOG_DATA, MatDialogModule, MatDialogRef } from '@angular/material/dialog';
import { MatIconModule } from '@angular/material/icon';
import { CurrentStock } from '../../core/models/stock.model';

export interface StockItemEditResult {
  targetStock: number;
  narration: string;
}

@Component({
  selector: 'app-stock-item-edit',
  standalone: true,
  imports: [DecimalPipe, ReactiveFormsModule, MatDialogModule, MatIconModule],
  templateUrl: './stock-item-edit.component.html',
  styleUrl: './stock-adjustment-form.component.scss'
})
export class StockItemEditComponent {
  private readonly fb = inject(FormBuilder);
  readonly data = inject<CurrentStock>(MAT_DIALOG_DATA);
  readonly dialogRef = inject(MatDialogRef<StockItemEditComponent>);

  readonly quantityUnit = this.data.tracksByBox ? 'kg' : this.data.unit;
  readonly form = this.fb.nonNullable.group({
    targetStock: [this.data.currentStock, [Validators.required, Validators.min(0)]],
    narration: ['', Validators.required]
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
