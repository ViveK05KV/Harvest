import { Component, inject } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { MatDialogModule, MAT_DIALOG_DATA, MatDialogRef } from '@angular/material/dialog';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatButtonModule } from '@angular/material/button';
import { Employee } from '../../core/models/master-data.model';

@Component({
  selector: 'app-employee-form',
  standalone: true,
  imports: [ReactiveFormsModule, MatDialogModule, MatFormFieldModule, MatInputModule, MatButtonModule],
  templateUrl: './employee-form.component.html'
})
export class EmployeeFormComponent {
  private readonly fb = inject(FormBuilder);
  readonly dialogRef = inject(MatDialogRef<EmployeeFormComponent>);
  readonly data = inject<Employee | null>(MAT_DIALOG_DATA);

  readonly form = this.fb.nonNullable.group({
    fullName: [this.data?.fullName ?? '', [Validators.required, Validators.maxLength(150)]],
    phone: [this.data?.phone ?? '', [Validators.maxLength(20)]],
    address: [this.data?.address ?? '']
  });

  save(): void {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }
    this.dialogRef.close(this.form.getRawValue());
  }
}
