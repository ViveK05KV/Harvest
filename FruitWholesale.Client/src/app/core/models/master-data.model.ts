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
  tracksByBox: boolean;
  boxWeightKg?: number | null;
  isActive: boolean;
}

export interface SaveFruitMaster {
  fruitID?: number;
  fruitName: string;
  unit: string;
  tracksByBox: boolean;
  boxWeightKg?: number | null;
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
  /** Optional link to a SupplierMaster row for a party that is both a shop and a supplier. */
  linkedSupplierID?: number | null;
  linkedSupplierName?: string;
  /** currentOutstanding minus the linked supplier's outstanding; equals currentOutstanding when not linked. */
  netBalance: number;
}

/** Posts a manual correcting entry to a shop's ledger (mirrors SupplierBalanceAdjustment). */
export interface ShopBalanceAdjustment {
  amount: number;
  /** True increases what this shop owes the business; false decreases it. */
  isIncrease: boolean;
  narration: string;
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
  linkedSupplierID?: number | null;
}

export interface SupplierMaster {
  supplierID: number;
  supplierName: string;
  phone?: string;
  address?: string;
  openingBalance: number;
  isActive: boolean;
  currentOutstanding: number;
  /** Reverse of ShopMaster.linkedSupplierID — the shop (if any) linked to this supplier. */
  linkedShopID?: number | null;
  linkedShopName?: string;
  /** Linked shop's outstanding minus this supplier's own outstanding; meaningless when not linked. */
  netBalance: number;
}

export interface SaveSupplierMaster {
  supplierID?: number;
  supplierName: string;
  phone?: string;
  address?: string;
  openingBalance?: number;
}

/** Posts a manual correcting entry to a supplier's ledger (mirrors CashAdjustment). */
export interface SupplierBalanceAdjustment {
  amount: number;
  /** True increases what the business owes this supplier; false decreases it. */
  isIncrease: boolean;
  narration: string;
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
  reportsVisibleToManagers: boolean;
  profitVisibleToManagers: boolean;
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
  salaryType: string;
  salaryAmount: number;
  isActive: boolean;
}

export interface SaveEmployee {
  employeeID?: number;
  fullName: string;
  phone?: string;
  address?: string;
  salaryType: string;
  salaryAmount: number;
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

export interface EmployeeLoanSummaryRow {
  employeeID: number;
  employeeName: string;
  salaryType: string;
  salaryAmount: number;
  outstandingLoan: number;
}

export interface EmployeeLoanHistoryRow {
  transactionDate: string;
  particulars: string;
  debit: number;
  credit: number;
  runningBalance: number;
  employeeLoanRepaymentID?: number | null;
}

export interface EmployeeLoanRepayment {
  employeeLoanRepaymentID: number;
  employeeID: number;
  employeeName: string;
  repaymentDate: string;
  amount: number;
  paymentMode: string;
  remarks?: string;
}

export interface SaveEmployeeLoanRepayment {
  employeeLoanRepaymentID?: number;
  employeeID: number | null;
  repaymentDate: string;
  amount: number;
  paymentMode: string;
  remarks?: string;
}
