import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { AuthService } from '../services/auth.service';
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

export const homeGuard: CanActivateFn = () => {
  const authService = inject(AuthService);
  const router = inject(Router);
  return router.createUrlTree([defaultRouteForRole(authService.role())]);
};
