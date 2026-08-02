import { Component, inject } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { MatDialogModule, MAT_DIALOG_DATA, MatDialogRef } from '@angular/material/dialog';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatButtonModule } from '@angular/material/button';
import { MatSelectModule } from '@angular/material/select';
import { MatCheckboxModule } from '@angular/material/checkbox';
import { FruitMaster } from '../../core/models/master-data.model';

const UNITS = ['Kg', 'Gram', 'Dozen', 'Box', 'Piece', 'Bag', 'Crate'];

@Component({
  selector: 'app-fruit-master-form',
  standalone: true,
  imports: [
    ReactiveFormsModule,
    MatDialogModule,
    MatFormFieldModule,
    MatInputModule,
    MatButtonModule,
    MatSelectModule,
    MatCheckboxModule
  ],
  templateUrl: './fruit-master-form.component.html'
})
export class FruitMasterFormComponent {
  private readonly fb = inject(FormBuilder);
  readonly dialogRef = inject(MatDialogRef<FruitMasterFormComponent>);
  readonly data = inject<FruitMaster | null>(MAT_DIALOG_DATA);

  readonly units = UNITS;

  readonly form = this.fb.nonNullable.group({
    fruitName: [this.data?.fruitName ?? '', [Validators.required, Validators.maxLength(150)]],
    unit: [this.data?.unit ?? 'Kg', [Validators.required]],
    tracksByBox: [this.data?.tracksByBox ?? false],
    boxWeightKg: this.fb.control<number | null>(this.data?.boxWeightKg ?? null, Validators.min(0.001))
  });

  save(): void {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }
    const raw = this.form.getRawValue();
    this.dialogRef.close({ ...raw, boxWeightKg: raw.tracksByBox ? raw.boxWeightKg : null });
  }
}
