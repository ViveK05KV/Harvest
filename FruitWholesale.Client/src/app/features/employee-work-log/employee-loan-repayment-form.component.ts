import { Component, inject } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { MatDialogModule, MAT_DIALOG_DATA, MatDialogRef } from '@angular/material/dialog';
import { MatIconModule } from '@angular/material/icon';
import { EmployeeLoanRepayment } from '../../core/models/master-data.model';
import { PAYMENT_MODES } from '../../core/models/common.model';
import { toIso } from '../../core/utils/date.util';

export interface EmployeeLoanRepaymentFormData {
  employeeId: number;
  employeeName: string;
  repayment: EmployeeLoanRepayment | null;
}

@Component({
  selector: 'app-employee-loan-repayment-form',
  standalone: true,
  imports: [ReactiveFormsModule, MatDialogModule, MatIconModule],
  templateUrl: './employee-loan-repayment-form.component.html',
  styleUrl: './employee-loan-repayment-form.component.scss'
})
export class EmployeeLoanRepaymentFormComponent {
  private readonly fb = inject(FormBuilder);
  readonly dialogRef = inject(MatDialogRef<EmployeeLoanRepaymentFormComponent>);
  readonly data = inject<EmployeeLoanRepaymentFormData>(MAT_DIALOG_DATA);

  readonly paymentModes = PAYMENT_MODES;

  readonly form = this.fb.nonNullable.group({
    repaymentDate: [this.data.repayment ? this.data.repayment.repaymentDate.slice(0, 10) : toIso(new Date()), Validators.required],
    amount: [this.data.repayment?.amount ?? 0, [Validators.required, Validators.min(0.01)]],
    paymentMode: [this.data.repayment?.paymentMode ?? 'Cash', Validators.required],
    remarks: [this.data.repayment?.remarks ?? '']
  });

  setPaymentMode(mode: string): void {
    this.form.controls.paymentMode.setValue(mode);
  }

  cancel(): void {
    this.dialogRef.close();
  }

  save(): void {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }
    this.dialogRef.close({
      ...this.form.getRawValue(),
      employeeID: this.data.employeeId
    });
  }
}
