import { Component, OnInit, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { MatDialogModule, MAT_DIALOG_DATA, MatDialogRef } from '@angular/material/dialog';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';
import { MatButtonModule } from '@angular/material/button';
import { MatDatepickerModule } from '@angular/material/datepicker';
import { MatNativeDateModule } from '@angular/material/core';
import { ExpenseCategoryService } from '../expense-category/expense-category.service';
import { ExpenseCategory } from '../../core/models/master-data.model';
import { DailyExpense } from '../../core/models/transactions.model';
import { PAYMENT_MODES } from '../../core/models/common.model';

@Component({
  selector: 'app-daily-expense-form',
  standalone: true,
  imports: [
    ReactiveFormsModule,
    MatDialogModule,
    MatFormFieldModule,
    MatInputModule,
    MatSelectModule,
    MatButtonModule,
    MatDatepickerModule,
    MatNativeDateModule
  ],
  templateUrl: './daily-expense-form.component.html'
})
export class DailyExpenseFormComponent implements OnInit {
  private readonly fb = inject(FormBuilder);
  private readonly categoryService = inject(ExpenseCategoryService);
  readonly dialogRef = inject(MatDialogRef<DailyExpenseFormComponent>);
  readonly data = inject<DailyExpense | null>(MAT_DIALOG_DATA);

  readonly paymentModes = PAYMENT_MODES;
  readonly categories = signal<ExpenseCategory[]>([]);

  readonly form = this.fb.nonNullable.group({
    expenseDate: [this.data ? new Date(this.data.expenseDate) : new Date(), Validators.required],
    expenseCategoryID: this.fb.control<number | null>(this.data?.expenseCategoryID ?? null, Validators.required),
    amount: [this.data?.amount ?? 0, [Validators.required, Validators.min(0.01)]],
    paymentMode: [this.data?.paymentMode ?? 'Cash', Validators.required],
    paidTo: [this.data?.paidTo ?? ''],
    description: [this.data?.description ?? '']
  });

  ngOnInit(): void {
    this.categoryService.getAllActive().subscribe((categories) => this.categories.set(categories));
  }

  save(): void {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }
    const raw = this.form.getRawValue();
    this.dialogRef.close({
      ...raw,
      expenseDate: (raw.expenseDate as unknown as Date).toISOString().slice(0, 10)
    });
  }
}
