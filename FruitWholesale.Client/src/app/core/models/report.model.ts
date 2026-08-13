export interface DailySalesReportRow {
  supplyDate: string;
  invoiceNo: string;
  shopName: string;
  totalAmount: number;
}

export interface DailyCollectionReportRow {
  collectionDate: string;
  shopName: string;
  amountReceived: number;
  paymentMode: string;
}

export interface DailyExpenseReportRow {
  expenseDate: string;
  categoryName: string;
  amount: number;
  paidTo: string;
  paymentMode: string;
}

export interface PurchaseReportRow {
  purchaseDate: string;
  invoiceNo: string;
  supplierName: string;
  totalAmount: number;
}

export interface FruitSalesReportRow {
  fruitName: string;
  unit: string;
  totalQuantity: number;
  totalAmount: number;
}

export interface OutstandingReportRow {
  name: string;
  type: string;
  outstandingAmount: number;
}

export interface ProfitSummaryReportRow {
  month: string;
  totalSales: number;
  totalPurchases: number;
  totalExpenses: number;
  netProfit: number;
}

export interface ExpenseByCategoryReportRow {
  categoryName: string;
  totalAmount: number;
}

export interface SalaryByEmployeeReportRow {
  employeeID: number;
  employeeName: string;
  workDaysCount: number;
  totalAmount: number;
}
