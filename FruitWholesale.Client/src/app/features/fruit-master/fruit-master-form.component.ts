import { Component, inject } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { MatDialogModule, MAT_DIALOG_DATA, MatDialogRef } from '@angular/material/dialog';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatButtonModule } from '@angular/material/button';
import { MatSelectModule } from '@angular/material/select';
import { FruitMaster } from '../../core/models/master-data.model';

const UNITS = ['Kg', 'Gram', 'Dozen', 'Box', 'Piece', 'Bag', 'Crate'];

@Component({
  selector: 'app-fruit-master-form',
  standalone: true,
  imports: [ReactiveFormsModule, MatDialogModule, MatFormFieldModule, MatInputModule, MatButtonModule, MatSelectModule],
  templateUrl: './fruit-master-form.component.html'
})
export class FruitMasterFormComponent {
  private readonly fb = inject(FormBuilder);
  readonly dialogRef = inject(MatDialogRef<FruitMasterFormComponent>);
  readonly data = inject<FruitMaster | null>(MAT_DIALOG_DATA);

  readonly units = UNITS;

  readonly form = this.fb.nonNullable.group({
    fruitName: [this.data?.fruitName ?? '', [Validators.required, Validators.maxLength(150)]],
    unit: [this.data?.unit ?? 'Kg', [Validators.required]]
  });

  save(): void {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }
    this.dialogRef.close(this.form.getRawValue());
  }
}
