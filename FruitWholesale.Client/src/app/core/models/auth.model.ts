import { UserRole } from './common.model';

export interface LoginRequest {
  username: string;
  password: string;
}

export interface LoginResponse {
  token: string;
  expiresAt: string;
  userID: number;
  fullName: string;
  username: string;
  role: UserRole;
}

export interface ChangePasswordRequest {
  currentPassword: string;
  newPassword: string;
}

export interface CurrentUser {
  userId: number;
  fullName: string;
  username: string;
  role: UserRole;
}
