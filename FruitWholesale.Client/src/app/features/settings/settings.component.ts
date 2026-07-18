import { Component, OnInit, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { MatTabsModule } from '@angular/material/tabs';
import { MatCardModule } from '@angular/material/card';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatRadioModule } from '@angular/material/radio';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { finalize } from 'rxjs';
import { SettingsService } from './settings.service';
import { AuthService } from '../../core/services/auth.service';
import { NotificationService } from '../../core/services/notification.service';
import { BrandingService } from '../../core/services/branding.service';

const MAX_LOGO_SIZE_BYTES = 2 * 1024 * 1024;
const ALLOWED_LOGO_TYPES = ['image/png', 'image/jpeg', 'image/svg+xml', 'image/webp'];

@Component({
  selector: 'app-settings',
  standalone: true,
  imports: [
    ReactiveFormsModule,
    MatTabsModule,
    MatCardModule,
    MatFormFieldModule,
    MatInputModule,
    MatButtonModule,
    MatIconModule,
    MatRadioModule,
    MatProgressSpinnerModule
  ],
  templateUrl: './settings.component.html'
})
export class SettingsComponent implements OnInit {
  private readonly fb = inject(FormBuilder);
  private readonly settingsService = inject(SettingsService);
  private readonly notification = inject(NotificationService);
  readonly authService = inject(AuthService);
  readonly branding = inject(BrandingService);

  readonly loading = signal(true);
  readonly savingProfile = signal(false);
  readonly savingPassword = signal(false);
  readonly savingAdjustment = signal(false);
  readonly uploadingLogo = signal(false);
  readonly companyId = signal<number | null>(null);

  readonly canAdjustCash = this.authService.hasRole('Admin', 'Accountant');

  readonly profileForm = this.fb.nonNullable.group({
    companyName: ['', [Validators.required, Validators.maxLength(200)]],
    ownerName: [''],
    address: [''],
    phone: [''],
    gstNo: [''],
    openingCashBalance: [{ value: 0, disabled: true }]
  });

  readonly passwordForm = this.fb.nonNullable.group({
    currentPassword: ['', Validators.required],
    newPassword: ['', [Validators.required, Validators.minLength(6)]]
  });

  readonly adjustmentForm = this.fb.nonNullable.group({
    isIncrease: [true, Validators.required],
    amount: [0, [Validators.required, Validators.min(0.01)]],
    narration: ['', Validators.required]
  });

  ngOnInit(): void {
    this.settingsService.get().subscribe({
      next: (settings) => {
        this.companyId.set(settings.companyID);
        this.profileForm.patchValue(settings);
        this.branding.companySettings.set(settings);
        this.loading.set(false);
      },
      error: () => this.loading.set(false)
    });
  }

  saveProfile(): void {
    if (this.profileForm.invalid) {
      this.profileForm.markAllAsTouched();
      return;
    }
    this.savingProfile.set(true);
    this.settingsService
      .save(this.profileForm.getRawValue())
      .pipe(finalize(() => this.savingProfile.set(false)))
      .subscribe({
        next: (settings) => {
          this.companyId.set(settings.companyID);
          this.branding.companySettings.update((current) => ({ ...current, ...settings }));
          this.notification.success('Company settings saved.');
        }
      });
  }

  onLogoSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0];
    input.value = '';
    if (!file) return;

    if (!ALLOWED_LOGO_TYPES.includes(file.type)) {
      this.notification.error('Logo must be a PNG, JPG, SVG, or WEBP image.');
      return;
    }
    if (file.size > MAX_LOGO_SIZE_BYTES) {
      this.notification.error('Logo must be 2 MB or smaller.');
      return;
    }
    if (!this.companyId()) {
      this.notification.error('Save the company profile before uploading a logo.');
      return;
    }

    this.uploadingLogo.set(true);
    this.settingsService
      .uploadLogo(file)
      .pipe(finalize(() => this.uploadingLogo.set(false)))
      .subscribe({
        next: (settings) => {
          this.branding.companySettings.update((current) => ({ ...current, ...settings }));
          this.notification.success('Logo updated.');
        }
      });
  }

  changePassword(): void {
    if (this.passwordForm.invalid) {
      this.passwordForm.markAllAsTouched();
      return;
    }
    this.savingPassword.set(true);
    this.authService
      .changePassword(this.passwordForm.getRawValue())
      .pipe(finalize(() => this.savingPassword.set(false)))
      .subscribe({
        next: () => {
          this.notification.success('Password changed successfully.');
          this.passwordForm.reset({ currentPassword: '', newPassword: '' });
        }
      });
  }

  applyAdjustment(): void {
    if (this.adjustmentForm.invalid) {
      this.adjustmentForm.markAllAsTouched();
      return;
    }
    this.savingAdjustment.set(true);
    this.settingsService
      .applyCashAdjustment(this.adjustmentForm.getRawValue())
      .pipe(finalize(() => this.savingAdjustment.set(false)))
      .subscribe({
        next: () => {
          this.notification.success('Cash adjustment applied.');
          this.adjustmentForm.reset({ isIncrease: true, amount: 0, narration: '' });
        }
      });
  }
}
