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

export const DASHBOARD_PERIODS = ['ThisWeek', 'ThisMonth', 'Last6Months', 'Last12Months'] as const;
export type DashboardPeriod = (typeof DASHBOARD_PERIODS)[number];

export const DASHBOARD_PERIOD_LABELS: Record<DashboardPeriod, string> = {
  ThisWeek: 'This Week',
  ThisMonth: 'This Month',
  Last6Months: 'Last 6 Months',
  Last12Months: 'Last 12 Months'
};

export interface TrendPoint {
  label: string;
  amount: number;
}

export interface SalesVsPurchases {
  sales: TrendPoint[];
  purchases: TrendPoint[];
}
