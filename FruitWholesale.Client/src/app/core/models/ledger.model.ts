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
