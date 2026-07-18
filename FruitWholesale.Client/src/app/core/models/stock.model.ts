export interface CurrentStock {
  fruitID: number;
  fruitName: string;
  unit: string;
  currentStock: number;
}

export interface StockLedgerEntry {
  stockLedgerID: number;
  transactionDate: string;
  transactionType: string;
  referenceID?: number;
  quantityIn: number;
  quantityOut: number;
  runningStock: number;
  narration?: string;
}

export interface StockAdjustment {
  fruitID: number;
  quantity: number;
  isIncrease: boolean;
  narration: string;
}
