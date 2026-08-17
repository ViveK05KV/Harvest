import { HttpInterceptorFn } from '@angular/common/http';
import { inject } from '@angular/core';
import { AuthService } from '../services/auth.service';

export const authInterceptor: HttpInterceptorFn = (req, next) => {
  const authService = inject(AuthService);
  const token = authService.getToken();

  if (!token) {
    return next(req);
  }

  // Sent as X-Authorization, not Authorization: in production the request reaches the API through
  // CloudFront, whose OAC signs every origin request and overwrites Authorization with its own SigV4
  // signature. The API promotes this header back onto Authorization before authenticating.
  return next(req.clone({ setHeaders: { 'X-Authorization': `Bearer ${token}` } }));
};
