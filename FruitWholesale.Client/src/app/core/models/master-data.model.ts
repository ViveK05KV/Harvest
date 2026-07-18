import { UserRole } from './common.model';

export interface User {
  userID: number;
  fullName: string;
  username: string;
  role: UserRole;
  isActive: boolean;
  createdAt: string;
}

export interface CreateUser {
  fullName: string;
  username: string;
  password: string;
  role: UserRole;
}

export interface UpdateUser {
  userID: number;
  fullName: string;
  role: UserRole;
}

export interface FruitMaster {
  fruitID: number;
  fruitName: string;
  unit: string;
  isActive: boolean;
}

export interface SaveFruitMaster {
  fruitID?: number;
  fruitName: string;
  unit: string;
}

export interface ShopMaster {
  shopID: number;
  shopName: string;
  ownerName?: string;
  phone?: string;
  address?: string;
  openingBalance: number;
  creditLimit: number;
  routeID?: number | null;
  routeName?: string;
  isActive: boolean;
  currentOutstanding: number;
}

export interface SaveShopMaster {
  shopID?: number;
  shopName: string;
  ownerName?: string;
  phone?: string;
  address?: string;
  openingBalance?: number;
  creditLimit: number;
  routeID?: number | null;
}

export interface SupplierMaster {
  supplierID: number;
  supplierName: string;
  phone?: string;
  address?: string;
  openingBalance: number;
  isActive: boolean;
  currentOutstanding: number;
}

export interface SaveSupplierMaster {
  supplierID?: number;
  supplierName: string;
  phone?: string;
  address?: string;
  openingBalance?: number;
}

export interface ExpenseCategory {
  expenseCategoryID: number;
  categoryName: string;
  description?: string;
  isActive: boolean;
}

export interface SaveExpenseCategory {
  expenseCategoryID?: number;
  categoryName: string;
  description?: string;
}

export interface CompanySettings {
  companyID: number;
  companyName: string;
  ownerName?: string;
  address?: string;
  phone?: string;
  gstNo?: string;
  logoUrl?: string;
  openingCashBalance: number;
}

export interface SaveCompanySettings {
  companyName: string;
  ownerName?: string;
  address?: string;
  phone?: string;
  gstNo?: string;
  openingCashBalance: number;
}

export interface CashAdjustment {
  amount: number;
  isIncrease: boolean;
  narration: string;
}

export interface RouteMaster {
  routeID: number;
  routeName: string;
  description?: string;
  isActive: boolean;
  shopCount: number;
}

export interface SaveRouteMaster {
  routeID?: number;
  routeName: string;
  description?: string;
}

export interface Employee {
  employeeID: number;
  fullName: string;
  phone?: string;
  address?: string;
  isActive: boolean;
}

export interface SaveEmployee {
  employeeID?: number;
  fullName: string;
  phone?: string;
  address?: string;
}

export interface EmployeeWorkLog {
  employeeWorkLogID: number;
  workDate: string;
  employeeID: number;
  employeeName: string;
  jobType: string;
  routeID?: number | null;
  routeName?: string;
  amount: number;
  paymentMode: string;
  remarks?: string;
}

export interface SaveEmployeeWorkLog {
  employeeWorkLogID?: number;
  workDate: string;
  employeeID: number | null;
  jobType: string;
  routeID?: number | null;
  amount: number;
  paymentMode: string;
  remarks?: string;
}
