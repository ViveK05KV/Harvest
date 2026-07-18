export interface PaginatedList<T> {
  items: T[];
  pageNumber: number;
  pageSize: number;
  totalCount: number;
  totalPages: number;
  hasPreviousPage: boolean;
  hasNextPage: boolean;
}

export interface PaginationRequest {
  pageNumber: number;
  pageSize: number;
  searchTerm?: string | null;
  sortBy?: string | null;
  sortDescending?: boolean;
}

export interface ApiError {
  title?: string;
  detail?: string;
  errors?: string[] | Record<string, string[]>;
}

export const PAYMENT_MODES = ['Cash', 'Bank', 'UPI', 'Cheque'] as const;
export type PaymentMode = (typeof PAYMENT_MODES)[number];

export const USER_ROLES = ['Admin', 'Manager', 'Accountant', 'Staff'] as const;
export type UserRole = (typeof USER_ROLES)[number];

export const JOB_TYPES = ['Supply', 'Collection', 'Loading', 'Other'] as const;
export type JobType = (typeof JOB_TYPES)[number];
