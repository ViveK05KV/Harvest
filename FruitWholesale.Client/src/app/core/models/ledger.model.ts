export interface ShopLedgerEntry {
  ledgerID: number;
  transactionDate: string;
  transactionType: string;
  referenceID?: number;
  debit: number;
  credit: number;
  runningBalance: number;
  narration?: string;
}

export interface SupplierLedgerEntry {
  ledgerID: number;
  transactionDate: string;
  transactionType: string;
  referenceID?: number;
  debit: number;
  credit: number;
  runningBalance: number;
  narration?: string;
}

// Raw TransactionType values (see LedgerTransactionTypes on the backend) mapped
// to the "Particulars" wording an accountant expects on a party ledger, rather
// than the internal enum name.
const LEDGER_PARTICULARS: Record<string, string> = {
  OpeningBalance: 'Opening Balance',
  Supply: 'Invoice',
  Collection: 'Payment',
  ShopReturn: 'Return',
  Purchase: 'Purchase',
  SupplierPayment: 'Payment',
  SupplierReturn: 'Return',
  Adjustment: 'Adjustment'
};

export function ledgerParticulars(transactionType: string): string {
  return LEDGER_PARTICULARS[transactionType] ?? transactionType;
}

// Transaction types that actually post to CashLedger (see LedgerTransactionTypes on the backend).
export const CASH_LEDGER_TRANSACTION_TYPES = ['OpeningBalance', 'Collection', 'SupplierPayment', 'DailyExpense', 'EmployeeWorkLog'] as const;

// Distinct labels for the cash ledger type filter — unlike ledgerParticulars(), Collection and
// SupplierPayment must stay distinguishable here since both appear together in one dropdown.
const CASH_LEDGER_TYPE_LABELS: Record<string, string> = {
  OpeningBalance: 'Opening Balance',
  Collection: 'Collection (from shop)',
  SupplierPayment: 'Supplier Payment',
  DailyExpense: 'Daily Expense',
  EmployeeWorkLog: 'Employee Wages'
};

export function cashLedgerTypeLabel(transactionType: string): string {
  return CASH_LEDGER_TYPE_LABELS[transactionType] ?? transactionType;
}

export interface CashLedgerEntry {
  cashLedgerID: number;
  transactionDate: string;
  transactionType: string;
  referenceTable: string;
  referenceID?: number;
  paymentMode: string;
  cashIn: number;
  cashOut: number;
  runningBalance: number;
  narration?: string;
}
