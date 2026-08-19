import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { map } from 'rxjs';
import { AuthService } from '../services/auth.service';
import { BrandingService } from '../services/branding.service';
import { CompanySettings } from '../models/master-data.model';
import { UserRole } from '../models/common.model';

export const defaultRouteForRole = (role: UserRole | null): string => (role === 'Staff' ? '/supply' : '/dashboard');

export const roleGuard = (...roles: UserRole[]): CanActivateFn => {
  return () => {
    const authService = inject(AuthService);
    const router = inject(Router);

    if (authService.hasRole(...roles)) {
      return true;
    }

    return router.createUrlTree([defaultRouteForRole(authService.role())]);
  };
};

// Admin always gets in; Manager only when the admin has switched the given
// CompanySettings flag on (see settings.component's "Manager Access" card).
const managerFeatureGuard = (flag: (settings: CompanySettings) => boolean): CanActivateFn => {
  return () => {
    const authService = inject(AuthService);
    const branding = inject(BrandingService);
    const router = inject(Router);
    const fallback = () => router.createUrlTree([defaultRouteForRole(authService.role())]);

    if (authService.hasRole('Admin')) return true;
    if (!authService.hasRole('Manager')) return fallback();

    return branding.ensureLoaded().pipe(map((settings) => (settings && flag(settings) ? true : fallback())));
  };
};

export const reportsGuard = managerFeatureGuard((s) => s.reportsVisibleToManagers);
export const profitGuard = managerFeatureGuard((s) => s.profitVisibleToManagers);

export const homeGuard: CanActivateFn = () => {
  const authService = inject(AuthService);
  const router = inject(Router);
  return router.createUrlTree([defaultRouteForRole(authService.role())]);
};
