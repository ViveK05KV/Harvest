import { Component, OnInit, inject, signal } from '@angular/core';
import { CurrencyPipe } from '@angular/common';
import { FormBuilder, ReactiveFormsModule, ValidationErrors, Validators } from '@angular/forms';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { finalize } from 'rxjs';
import { SettingsService } from './settings.service';
import { AuthService } from '../../core/services/auth.service';
import { NotificationService } from '../../core/services/notification.service';
import { BrandingService } from '../../core/services/branding.service';
import { LedgerService } from '../ledgers/ledger.service';

function passwordsMatch(group: import('@angular/forms').AbstractControl): ValidationErrors | null {
  const newPassword = group.get('newPassword')?.value;
  const confirmPassword = group.get('confirmPassword')?.value;
  return newPassword === confirmPassword ? null : { mismatch: true };
}

const MAX_LOGO_SIZE_BYTES = 2 * 1024 * 1024;
const ALLOWED_LOGO_TYPES = ['image/png', 'image/jpeg', 'image/svg+xml', 'image/webp'];

@Component({
  selector: 'app-settings',
  standalone: true,
  imports: [ReactiveFormsModule, CurrencyPipe, MatProgressSpinnerModule],
  templateUrl: './settings.component.html',
  styleUrl: './settings.component.scss'
})
export class SettingsComponent implements OnInit {
  private readonly fb = inject(FormBuilder);
  private readonly settingsService = inject(SettingsService);
  private readonly notification = inject(NotificationService);
  private readonly ledgerService = inject(LedgerService);
  readonly authService = inject(AuthService);
  readonly branding = inject(BrandingService);

  readonly loading = signal(true);
  readonly savingProfile = signal(false);
  readonly savingPassword = signal(false);
  readonly savingUsername = signal(false);
  readonly savingAdjustment = signal(false);
  readonly savingReportsVisibility = signal(false);
  readonly savingProfitVisibility = signal(false);
  readonly uploadingLogo = signal(false);
  readonly companyId = signal<number | null>(null);
  readonly cashBalance = signal<number | null>(null);

  readonly isAdmin = this.authService.hasRole('Admin');
  readonly canAdjustCash = this.authService.hasRole('Admin', 'Accountant');

  readonly profileForm = this.fb.nonNullable.group({
    companyName: ['', [Validators.required, Validators.maxLength(200)]],
    ownerName: [''],
    address: [''],
    phone: [''],
    gstNo: [''],
    openingCashBalance: [{ value: 0, disabled: true }]
  });

  readonly passwordForm = this.fb.nonNullable.group(
    {
      currentPassword: ['', Validators.required],
      newPassword: ['', [Validators.required, Validators.minLength(6)]],
      confirmPassword: ['', Validators.required]
    },
    { validators: passwordsMatch }
  );

  readonly usernameForm = this.fb.nonNullable.group({
    newUsername: [
      this.authService.currentUser()?.username ?? '',
      [Validators.required, Validators.maxLength(100), Validators.pattern(/^[a-zA-Z0-9._-]+$/)]
    ],
    currentPassword: ['', Validators.required]
  });

  readonly adjustmentForm = this.fb.nonNullable.group({
    isIncrease: [true, Validators.required],
    amount: [0, [Validators.required, Validators.min(0.01)]],
    narration: ['', Validators.required]
  });

  onDirectionChange(value: string): void {
    this.adjustmentForm.controls.isIncrease.setValue(value === 'in');
  }

  changeUsername(): void {
    if (this.usernameForm.invalid) {
      this.usernameForm.markAllAsTouched();
      return;
    }
    this.savingUsername.set(true);
    this.authService
      .changeUsername(this.usernameForm.getRawValue())
      .pipe(finalize(() => this.savingUsername.set(false)))
      .subscribe({
        next: () => {
          this.notification.success('Username changed successfully.');
          this.usernameForm.controls.currentPassword.reset('');
        }
      });
  }

  toggleReportsVisibility(): void {
    const next = !this.branding.companySettings()?.reportsVisibleToManagers;
    this.savingReportsVisibility.set(true);
    this.settingsService
      .setReportsVisibility(next)
      .pipe(finalize(() => this.savingReportsVisibility.set(false)))
      .subscribe({
        next: (settings) => {
          this.branding.companySettings.update((current) => (current ? { ...current, ...settings } : settings));
          this.notification.success(next ? 'Reports is now visible to Managers.' : 'Reports is now hidden from Managers.');
        }
      });
  }

  toggleProfitVisibility(): void {
    const next = !this.branding.companySettings()?.profitVisibleToManagers;
    this.savingProfitVisibility.set(true);
    this.settingsService
      .setProfitVisibility(next)
      .pipe(finalize(() => this.savingProfitVisibility.set(false)))
      .subscribe({
        next: (settings) => {
          this.branding.companySettings.update((current) => (current ? { ...current, ...settings } : settings));
          this.notification.success(next ? 'Profit Calculator is now visible to Managers.' : 'Profit Calculator is now hidden from Managers.');
        }
      });
  }

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

    if (this.canAdjustCash) {
      this.ledgerService.getCurrentCashBalance().subscribe((balance) => this.cashBalance.set(balance));
    }
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
          this.passwordForm.reset({ currentPassword: '', newPassword: '', confirmPassword: '' });
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
          this.ledgerService.getCurrentCashBalance().subscribe((balance) => this.cashBalance.set(balance));
        }
      });
  }
}
