import { Component, inject } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { MatDialogModule, MAT_DIALOG_DATA, MatDialogRef } from '@angular/material/dialog';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';
import { MatButtonModule } from '@angular/material/button';
import { User } from '../../core/models/master-data.model';
import { USER_ROLES } from '../../core/models/common.model';

@Component({
  selector: 'app-user-form',
  standalone: true,
  imports: [ReactiveFormsModule, MatDialogModule, MatFormFieldModule, MatInputModule, MatSelectModule, MatButtonModule],
  templateUrl: './user-form.component.html'
})
export class UserFormComponent {
  private readonly fb = inject(FormBuilder);
  readonly dialogRef = inject(MatDialogRef<UserFormComponent>);
  readonly data = inject<User | null>(MAT_DIALOG_DATA);
  readonly isEdit = !!this.data;

  readonly roles = USER_ROLES;

  readonly form = this.fb.nonNullable.group({
    fullName: [this.data?.fullName ?? '', [Validators.required, Validators.maxLength(150)]],
    username: [
      { value: this.data?.username ?? '', disabled: this.isEdit },
      [Validators.required, Validators.maxLength(100), Validators.pattern(/^[a-zA-Z0-9._-]+$/)]
    ],
    password: ['', this.isEdit ? [] : [Validators.required, Validators.minLength(6)]],
    role: [this.data?.role ?? 'Staff', Validators.required]
  });

  save(): void {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }
    this.dialogRef.close(this.form.getRawValue());
  }
}
