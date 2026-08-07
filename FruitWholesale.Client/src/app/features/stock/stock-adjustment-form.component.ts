import { Component, OnInit, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { MatDialogModule, MatDialogRef } from '@angular/material/dialog';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';
import { MatAutocompleteModule, MatAutocompleteSelectedEvent } from '@angular/material/autocomplete';
import { MatButtonModule } from '@angular/material/button';
import { MatRadioModule } from '@angular/material/radio';
import { FruitMasterService } from '../fruit-master/fruit-master.service';
import { FruitMaster } from '../../core/models/master-data.model';

@Component({
  selector: 'app-stock-adjustment-form',
  standalone: true,
  imports: [
    ReactiveFormsModule,
    MatDialogModule,
    MatFormFieldModule,
    MatInputModule,
    MatSelectModule,
    MatAutocompleteModule,
    MatButtonModule,
    MatRadioModule
  ],
  templateUrl: './stock-adjustment-form.component.html'
})
export class StockAdjustmentFormComponent implements OnInit {
  private readonly fb = inject(FormBuilder);
  private readonly fruitService = inject(FruitMasterService);
  readonly dialogRef = inject(MatDialogRef<StockAdjustmentFormComponent>);

  readonly fruits = signal<FruitMaster[]>([]);

  readonly form = this.fb.nonNullable.group({
    fruitID: this.fb.control<number | null>(null, Validators.required),
    fruitSearch: this.fb.nonNullable.control<string>(''),
    isIncrease: [true, Validators.required],
    quantity: [0, [Validators.required, Validators.min(0.001)]],
    narration: ['', Validators.required]
  });

  ngOnInit(): void {
    this.fruitService.getAllActive().subscribe((fruits) => this.fruits.set(fruits));
  }

  fruitNameById(fruitID: number | null): string {
    return this.fruits().find((f) => f.fruitID === fruitID)?.fruitName ?? '';
  }

  readonly displayFruit = (value: unknown): string =>
    typeof value === 'number' ? this.fruitNameById(value) : typeof value === 'string' ? value : '';

  filteredFruits(search: string | null | undefined): FruitMaster[] {
    const term = (search ?? '').trim().toLowerCase();
    if (!term) return this.fruits();
    return this.fruits().filter((f) => f.fruitName.toLowerCase().includes(term));
  }

  onFruitSelected(event: MatAutocompleteSelectedEvent): void {
    const fruitID = event.option.value as number;
    this.form.patchValue({ fruitID, fruitSearch: this.fruitNameById(fruitID) });
  }

  onFruitSearchFocus(): void {
    if (this.form.controls.fruitSearch.value === this.fruitNameById(this.form.controls.fruitID.value)) {
      this.form.controls.fruitSearch.setValue('');
    }
  }

  // Typing away from the settled fruit name must invalidate the stale fruitID -
  // otherwise the form stays "valid" with the old fruit while the field shows
  // different text, and save() would silently post against the wrong fruit.
  onFruitSearchInput(): void {
    this.form.controls.fruitID.setValue(null);
  }

  save(): void {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }
    const { fruitSearch, ...raw } = this.form.getRawValue();
    this.dialogRef.close(raw);
  }
}
