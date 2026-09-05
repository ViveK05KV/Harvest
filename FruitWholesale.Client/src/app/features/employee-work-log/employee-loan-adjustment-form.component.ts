import { Component, inject } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { MatDialogModule, MAT_DIALOG_DATA, MatDialogRef } from '@angular/material/dialog';
import { MatIconModule } from '@angular/material/icon';

export interface EmployeeLoanAdjustmentFormData {
  employeeId: number;
  employeeName: string;
}

@Component({
  selector: 'app-employee-loan-adjustment-form',
  standalone: true,
  imports: [ReactiveFormsModule, MatDialogModule, MatIconModule],
  templateUrl: './employee-loan-adjustment-form.component.html',
  styleUrl: './employee-loan-adjustment-form.component.scss'
})
export class EmployeeLoanAdjustmentFormComponent {
  private readonly fb = inject(FormBuilder);
  readonly dialogRef = inject(MatDialogRef<EmployeeLoanAdjustmentFormComponent>);
  readonly data = inject<EmployeeLoanAdjustmentFormData>(MAT_DIALOG_DATA);

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
