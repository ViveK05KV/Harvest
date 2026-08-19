import { Component, inject } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { MatDialogModule, MAT_DIALOG_DATA, MatDialogRef } from '@angular/material/dialog';
import { MatIconModule } from '@angular/material/icon';
import { User } from '../../core/models/master-data.model';
import { USER_ROLES } from '../../core/models/common.model';

@Component({
  selector: 'app-user-form',
  standalone: true,
  imports: [ReactiveFormsModule, MatDialogModule, MatIconModule],
  templateUrl: './user-form.component.html',
  styleUrl: './user-form.component.scss'
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
