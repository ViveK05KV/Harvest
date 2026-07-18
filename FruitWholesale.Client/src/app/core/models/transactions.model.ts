import { PaymentMode } from './common.model';

export interface SupplyItem {
  supplyItemID: number;
  fruitID: number;
  fruitName?: string;
  unit?: string;
  quantity: number;
  unitPrice: number;
  totalAmount: number;
}

export interface Supply {
  supplyID: number;
  supplyDate: string;
  shopID: number;
  shopName?: string;
  invoiceNo: string;
  remarks?: string;
  totalAmount: number;
  items: SupplyItem[];
}

export interface SupplyListItem {
  supplyID: number;
  supplyDate: string;
  shopName: string;
  invoiceNo: string;
  totalAmount: number;
}

export interface SaveSupplyItem {
  fruitID: number | null;
  quantity: number;
  unitPrice: number;
}

export interface SaveSupply {
  supplyID?: number;
  supplyDate: string;
  shopID: number | null;
  invoiceNo: string;
  remarks?: string;
  items: SaveSupplyItem[];
}

export interface PurchaseItem {
  purchaseItemID: number;
  fruitID: number;
  fruitName?: string;
  unit?: string;
  quantity: number;
  purchasePrice: number;
  totalAmount: number;
}

export interface Purchase {
  purchaseID: number;
  purchaseDate: string;
  supplierID: number;
  supplierName?: string;
  invoiceNo: string;
  remarks?: string;
  totalAmount: number;
  items: PurchaseItem[];
}

export interface PurchaseListItem {
  purchaseID: number;
  purchaseDate: string;
  supplierName: string;
  invoiceNo: string;
  totalAmount: number;
}

export interface SavePurchaseItem {
  fruitID: number | null;
  quantity: number;
  purchasePrice: number;
}

export interface SavePurchase {
  purchaseID?: number;
  purchaseDate: string;
  supplierID: number | null;
  invoiceNo: string;
  remarks?: string;
  items: SavePurchaseItem[];
}

export interface Collection {
  collectionID: number;
  collectionDate: string;
  shopID: number;
  shopName?: string;
  amountReceived: number;
  discountAmount: number;
  paymentMode: PaymentMode;
  referenceNumber?: string;
  remarks?: string;
}

export interface SaveCollection {
  collectionID?: number;
  collectionDate: string;
  shopID: number | null;
  amountReceived: number;
  discountAmount: number;
  paymentMode: PaymentMode;
  referenceNumber?: string;
  remarks?: string;
}

export interface SupplierPayment {
  supplierPaymentID: number;
  paymentDate: string;
  supplierID: number;
  supplierName?: string;
  amountPaid: number;
  discountAmount: number;
  paymentMode: PaymentMode;
  referenceNumber?: string;
  remarks?: string;
}

export interface SaveSupplierPayment {
  supplierPaymentID?: number;
  paymentDate: string;
  supplierID: number | null;
  amountPaid: number;
  discountAmount: number;
  paymentMode: PaymentMode;
  referenceNumber?: string;
  remarks?: string;
}

export interface DailyExpense {
  expenseID: number;
  expenseDate: string;
  expenseCategoryID: number;
  categoryName?: string;
  amount: number;
  paymentMode: PaymentMode;
  paidTo?: string;
  description?: string;
}

export interface SaveDailyExpense {
  expenseID?: number;
  expenseDate: string;
  expenseCategoryID: number | null;
  amount: number;
  paymentMode: PaymentMode;
  paidTo?: string;
  description?: string;
}
