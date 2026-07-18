import { Component, inject } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { MatDialogModule, MAT_DIALOG_DATA, MatDialogRef } from '@angular/material/dialog';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatButtonModule } from '@angular/material/button';
import { ExpenseCategory } from '../../core/models/master-data.model';

@Component({
  selector: 'app-expense-category-form',
  standalone: true,
  imports: [ReactiveFormsModule, MatDialogModule, MatFormFieldModule, MatInputModule, MatButtonModule],
  templateUrl: './expense-category-form.component.html'
})
export class ExpenseCategoryFormComponent {
  private readonly fb = inject(FormBuilder);
  readonly dialogRef = inject(MatDialogRef<ExpenseCategoryFormComponent>);
  readonly data = inject<ExpenseCategory | null>(MAT_DIALOG_DATA);

  readonly form = this.fb.nonNullable.group({
    categoryName: [this.data?.categoryName ?? '', [Validators.required, Validators.maxLength(150)]],
    description: [this.data?.description ?? '']
  });

  save(): void {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }
    this.dialogRef.close(this.form.getRawValue());
  }
}
