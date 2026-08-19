import { Injectable, computed, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Router } from '@angular/router';
import { jwtDecode } from 'jwt-decode';
import { Observable, tap } from 'rxjs';
import { environment } from '../../../environments/environment';
import { ChangePasswordRequest, ChangeUsernameRequest, CurrentUser, LoginRequest, LoginResponse } from '../models/auth.model';
import { UserRole } from '../models/common.model';

const TOKEN_KEY = 'fw_token';
const USER_KEY = 'fw_user';

interface JwtPayload {
  exp: number;
}

@Injectable({ providedIn: 'root' })
export class AuthService {
  private readonly baseUrl = `${environment.apiUrl}/auth`;
  private readonly currentUserSignal = signal<CurrentUser | null>(this.readStoredUser());

  readonly currentUser = this.currentUserSignal.asReadonly();
  readonly isAuthenticated = computed(() => this.currentUserSignal() !== null && !this.isTokenExpired());
  readonly role = computed(() => this.currentUserSignal()?.role ?? null);

  constructor(private readonly http: HttpClient, private readonly router: Router) {}

  login(request: LoginRequest): Observable<LoginResponse> {
    return this.http.post<LoginResponse>(`${this.baseUrl}/login`, request).pipe(
      tap((response) => {
        localStorage.setItem(TOKEN_KEY, response.token);
        const user: CurrentUser = {
          userId: response.userID,
          fullName: response.fullName,
          username: response.username,
          role: response.role
        };
        localStorage.setItem(USER_KEY, JSON.stringify(user));
        this.currentUserSignal.set(user);
      })
    );
  }

  changePassword(request: ChangePasswordRequest): Observable<void> {
    return this.http.post<void>(`${this.baseUrl}/change-password`, request);
  }

  changeUsername(request: ChangeUsernameRequest): Observable<string> {
    return this.http.post<string>(`${this.baseUrl}/change-username`, request).pipe(
      tap((newUsername) => {
        const current = this.currentUserSignal();
        if (!current) return;
        const updated: CurrentUser = { ...current, username: newUsername };
        localStorage.setItem(USER_KEY, JSON.stringify(updated));
        this.currentUserSignal.set(updated);
      })
    );
  }

  logout(): void {
    localStorage.removeItem(TOKEN_KEY);
    localStorage.removeItem(USER_KEY);
    this.currentUserSignal.set(null);
    this.router.navigate(['/login']);
  }

  getToken(): string | null {
    return localStorage.getItem(TOKEN_KEY);
  }

  hasRole(...roles: UserRole[]): boolean {
    const currentRole = this.currentUserSignal()?.role;
    return !!currentRole && roles.includes(currentRole);
  }

  private isTokenExpired(): boolean {
    const token = this.getToken();
    if (!token) return true;
    try {
      const payload = jwtDecode<JwtPayload>(token);
      return payload.exp * 1000 < Date.now();
    } catch {
      return true;
    }
  }

  private readStoredUser(): CurrentUser | null {
    const raw = localStorage.getItem(USER_KEY);
    if (!raw) return null;
    try {
      return JSON.parse(raw) as CurrentUser;
    } catch {
      return null;
    }
  }
}
