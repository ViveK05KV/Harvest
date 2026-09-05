import { Component, inject } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { MatDialogModule, MAT_DIALOG_DATA, MatDialogRef } from '@angular/material/dialog';
import { MatIconModule } from '@angular/material/icon';
import { Employee } from '../../core/models/master-data.model';
import { SALARY_TYPES } from '../../core/models/common.model';

@Component({
  selector: 'app-employee-form',
  standalone: true,
  imports: [ReactiveFormsModule, MatDialogModule, MatIconModule],
  templateUrl: './employee-form.component.html',
  styleUrl: './employee-form.component.scss'
})
export class EmployeeFormComponent {
  private readonly fb = inject(FormBuilder);
  readonly dialogRef = inject(MatDialogRef<EmployeeFormComponent>);
  readonly data = inject<Employee | null>(MAT_DIALOG_DATA);

  readonly salaryTypes = SALARY_TYPES;

  readonly form = this.fb.nonNullable.group({
    fullName: [this.data?.fullName ?? '', [Validators.required, Validators.maxLength(150)]],
    phone: [this.data?.phone ?? '', [Validators.maxLength(20)]],
    address: [this.data?.address ?? ''],
    salaryType: [this.data?.salaryType ?? 'Monthly', Validators.required],
    salaryAmount: [this.data?.salaryAmount ?? 0, [Validators.required, Validators.min(0)]]
  });

  setSalaryType(type: string): void {
    this.form.controls.salaryType.setValue(type);
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
