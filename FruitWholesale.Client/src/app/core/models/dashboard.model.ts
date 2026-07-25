export interface DashboardSummary {
  currentCashBalance: number;
  todayCollection: number;
  todaySales: number;
  todayPurchases: number;
  todayExpenses: number;
  customerOutstanding: number;
  supplierOutstanding: number;
  netBusinessWorth: number;
  totalProfit: number | null;
  todayProfit: number | null;
}

export interface MonthlyAmount {
  month: string;
  amount: number;
}

export interface CategoryAmount {
  category: string;
  amount: number;
}

export interface TopFruit {
  fruitName: string;
  totalQuantity: number;
  totalAmount: number;
}

export interface TopCustomer {
  shopName: string;
  totalAmount: number;
}

export interface DashboardCharts {
  salesByMonth: MonthlyAmount[];
  collectionsByMonth: MonthlyAmount[];
  expensesByCategory: CategoryAmount[];
  topSellingFruits: TopFruit[];
  topCustomers: TopCustomer[];
}
