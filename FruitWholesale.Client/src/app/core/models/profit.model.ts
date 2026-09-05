export interface ShopDailyProfitRow {
  date: string;
  revenue: number;
  cost: number;
  profit: number;
  marginPercent: number;
}

export interface ShopProfitSummaryRow {
  shopID: number;
  shopName: string;
  revenue: number;
  cost: number;
  profit: number;
  marginPercent: number;
}

export interface FruitProfitSummaryRow {
  fruitID: number;
  fruitName: string;
  unit: string;
  quantitySold: number;
  revenue: number;
  cost: number;
  profit: number;
  marginPercent: number;
}

export interface ShopFruitProfitRow {
  shopID: number;
  shopName: string;
  fruitID: number;
  fruitName: string;
  unit: string;
  quantitySold: number;
  revenue: number;
  cost: number;
  profit: number;
  marginPercent: number;
}

export interface BusinessProfitTotal {
  revenue: number;
  cost: number;
  profit: number;
  expenses: number;
  netProfit: number;
  marginPercent: number;
}
