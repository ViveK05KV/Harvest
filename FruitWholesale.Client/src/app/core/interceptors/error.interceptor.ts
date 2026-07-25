import { HttpErrorResponse, HttpInterceptorFn } from '@angular/common/http';
import { inject } from '@angular/core';
import { Router } from '@angular/router';
import { catchError, throwError } from 'rxjs';
import { AuthService } from '../services/auth.service';
import { NotificationService } from '../services/notification.service';
import { ApiError } from '../models/common.model';

export const errorInterceptor: HttpInterceptorFn = (req, next) => {
  const authService = inject(AuthService);
  const notification = inject(NotificationService);
  const router = inject(Router);

  return next(req).pipe(
    catchError((error: HttpErrorResponse) => {
      if (error.status === 401 && req.url.includes('/auth/login')) {
        notification.error(extractMessage(error));
      } else if (error.status === 401) {
        authService.logout();
        notification.error('Your session has expired. Please sign in again.');
      } else if (error.status === 403) {
        notification.error('You do not have permission to perform this action.');
        router.navigate(['/dashboard']);
      } else if (error.status === 0) {
        notification.error('Cannot reach the server. Please check your connection.');
      } else {
        notification.error(extractMessage(error));
      }
      return throwError(() => error);
    })
  );
};

function extractMessage(error: HttpErrorResponse): string {
  const body = error.error as ApiError | undefined;
  if (!body) return 'Something went wrong. Please try again.';

  if (Array.isArray(body.errors) && body.errors.length > 0) {
    return body.errors.join(' ');
  }
  if (body.errors && typeof body.errors === 'object') {
    const messages = Object.values(body.errors).flat();
    if (messages.length > 0) return messages.join(' ');
  }
  return body.detail ?? body.title ?? 'Something went wrong. Please try again.';
}
