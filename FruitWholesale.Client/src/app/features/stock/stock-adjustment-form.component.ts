import { Component, OnInit, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { MatDialogModule, MatDialogRef } from '@angular/material/dialog';
import { MatIconModule } from '@angular/material/icon';
import { FruitMasterService } from '../fruit-master/fruit-master.service';
import { FruitMaster } from '../../core/models/master-data.model';

@Component({
  selector: 'app-stock-adjustment-form',
  standalone: true,
  imports: [ReactiveFormsModule, MatDialogModule, MatIconModule],
  templateUrl: './stock-adjustment-form.component.html',
  styleUrl: './stock-adjustment-form.component.scss'
})
export class StockAdjustmentFormComponent implements OnInit {
  private readonly fb = inject(FormBuilder);
  private readonly fruitService = inject(FruitMasterService);
  readonly dialogRef = inject(MatDialogRef<StockAdjustmentFormComponent>);

  readonly fruits = signal<FruitMaster[]>([]);

  readonly form = this.fb.nonNullable.group({
    fruitID: this.fb.control<number | null>(null, Validators.required),
    isIncrease: this.fb.nonNullable.control<boolean>(true, Validators.required),
    quantity: [0, [Validators.required, Validators.min(0.001)]],
    narration: ['', Validators.required]
  });

  ngOnInit(): void {
    this.fruitService.getAllActive().subscribe((fruits) => this.fruits.set(fruits));
  }

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
