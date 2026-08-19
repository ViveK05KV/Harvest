import { Component, OnInit, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { MatDialogModule, MAT_DIALOG_DATA, MatDialogRef } from '@angular/material/dialog';
import { MatIconModule } from '@angular/material/icon';
import { ExpenseCategoryService } from '../expense-category/expense-category.service';
import { ExpenseCategory } from '../../core/models/master-data.model';
import { DailyExpense } from '../../core/models/transactions.model';
import { PAYMENT_MODES, PaymentMode } from '../../core/models/common.model';
import { toIso } from '../../core/utils/date.util';

@Component({
  selector: 'app-daily-expense-form',
  standalone: true,
  imports: [ReactiveFormsModule, MatDialogModule, MatIconModule],
  templateUrl: './daily-expense-form.component.html',
  styleUrl: './daily-expense-form.component.scss'
})
export class DailyExpenseFormComponent implements OnInit {
  private readonly fb = inject(FormBuilder);
  private readonly categoryService = inject(ExpenseCategoryService);
  readonly dialogRef = inject(MatDialogRef<DailyExpenseFormComponent>);
  readonly data = inject<DailyExpense | null>(MAT_DIALOG_DATA);

  readonly paymentModes = PAYMENT_MODES;
  readonly categories = signal<ExpenseCategory[]>([]);

  readonly form = this.fb.nonNullable.group({
    expenseDate: [this.data ? this.data.expenseDate.slice(0, 10) : toIso(new Date()), Validators.required],
    expenseCategoryID: this.fb.control<number | null>(this.data?.expenseCategoryID ?? null, Validators.required),
    amount: [this.data?.amount ?? 0, [Validators.required, Validators.min(0.01)]],
    paymentMode: this.fb.nonNullable.control<PaymentMode>(this.data?.paymentMode ?? 'Cash', Validators.required),
    paidTo: [this.data?.paidTo ?? ''],
    description: [this.data?.description ?? '']
  });

  ngOnInit(): void {
    this.categoryService.getAllActive().subscribe((categories) => this.categories.set(categories));
  }

  setPaymentMode(mode: PaymentMode): void {
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
    this.dialogRef.close(this.form.getRawValue());
  }
}
