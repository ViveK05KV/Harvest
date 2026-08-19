import { Component, inject } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { MatDialogModule, MAT_DIALOG_DATA, MatDialogRef } from '@angular/material/dialog';
import { MatIconModule } from '@angular/material/icon';
import { RouteMaster } from '../../core/models/master-data.model';

@Component({
  selector: 'app-route-master-form',
  standalone: true,
  imports: [ReactiveFormsModule, MatDialogModule, MatIconModule],
  templateUrl: './route-master-form.component.html',
  styleUrl: './route-master-form.component.scss'
})
export class RouteMasterFormComponent {
  private readonly fb = inject(FormBuilder);
  readonly dialogRef = inject(MatDialogRef<RouteMasterFormComponent>);
  readonly data = inject<RouteMaster | null>(MAT_DIALOG_DATA);

  readonly form = this.fb.nonNullable.group({
    routeName: [this.data?.routeName ?? '', [Validators.required, Validators.maxLength(150)]],
    description: [this.data?.description ?? '']
  });

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
