import { Component, OnInit, computed, inject, signal } from '@angular/core';
import { CurrencyPipe } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { MatCardModule } from '@angular/material/card';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { ChartConfiguration } from 'chart.js';
import { forkJoin } from 'rxjs';
import { ChartComponent } from '../../shared/chart/chart.component';
import { DashboardService } from './dashboard.service';
import { StockService } from '../stock/stock.service';
import { CurrentStock } from '../../core/models/stock.model';
import {
  DASHBOARD_PERIODS,
  DASHBOARD_PERIOD_LABELS,
  DashboardCharts,
  DashboardPeriod,
  DashboardSummary,
  TrendPoint
} from '../../core/models/dashboard.model';

interface SummaryCard {
  label: string;
  value: number;
  icon: string;
  emphasis?: boolean;
  tone: 'green' | 'amber' | 'sage' | 'slate';
}

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [CurrencyPipe, FormsModule, RouterLink, MatCardModule, MatIconModule, MatProgressSpinnerModule, ChartComponent],
  templateUrl: './dashboard.component.html',
  styleUrl: './dashboard.component.scss'
})
export class DashboardComponent implements OnInit {
  private readonly dashboardService = inject(DashboardService);
  private readonly stockService = inject(StockService);

  readonly loading = signal(true);
  readonly summary = signal<DashboardSummary | null>(null);
  readonly charts = signal<DashboardCharts | null>(null);

  readonly periodOptions = DASHBOARD_PERIODS;
  readonly periodLabel = (period: DashboardPeriod) => DASHBOARD_PERIOD_LABELS[period];

  readonly salesPeriod = signal<DashboardPeriod>('ThisWeek');
  readonly salesTrendLoading = signal(true);
  readonly salesTrend = signal<TrendPoint[]>([]);

  readonly svpPeriod = signal<DashboardPeriod>('ThisWeek');
  readonly svpLoading = signal(true);
  readonly svpSales = signal<TrendPoint[]>([]);
  readonly svpPurchases = signal<TrendPoint[]>([]);

  readonly cards = computed<SummaryCard[]>(() => {
    const s = this.summary();
    if (!s) return [];
    const cards: SummaryCard[] = [
      { label: 'Current Cash Balance', value: s.currentCashBalance, icon: 'account_balance_wallet', tone: 'green' },
      { label: "Today's Collection", value: s.todayCollection, icon: 'payments', tone: 'sage' },
      { label: "Today's Sales", value: s.todaySales, icon: 'point_of_sale', tone: 'green' },
      { label: "Today's Purchases", value: s.todayPurchases, icon: 'shopping_cart', tone: 'amber' },
      { label: "Today's Expenses", value: s.todayExpenses, icon: 'receipt_long', tone: 'slate' },
      { label: 'Customer Outstanding', value: s.customerOutstanding, icon: 'storefront', tone: 'amber' },
      { label: 'Supplier Outstanding', value: s.supplierOutstanding, icon: 'local_shipping', tone: 'slate' },
      { label: 'Net Business Worth', value: s.netBusinessWorth, icon: 'trending_up', emphasis: true, tone: 'green' }
    ];
    // totalProfit/todayProfit are only populated by the API for Admin users
    if (s.totalProfit !== null) {
      cards.push({ label: "Today's Profit", value: s.todayProfit ?? 0, icon: 'trending_up', tone: 'sage' });
      cards.push({ label: 'Total Profit', value: s.totalProfit, icon: 'savings', emphasis: true, tone: 'green' });
    }
    return cards;
  });

  readonly stockLoading = signal(true);
  readonly stockItems = signal<CurrentStock[]>([]);
  readonly lowStockItems = computed(() => [...this.stockItems()].sort((a, b) => a.currentStock - b.currentStock).slice(0, 8));
  readonly maxStockForBar = computed(() => Math.max(1, ...this.stockItems().map((i) => i.currentStock)));

  readonly salesChartData = computed<ChartConfiguration['data']>(() => this.toLineChart(this.salesTrend(), 'Sales'));

  readonly salesVsPurchasesChartData = computed<ChartConfiguration['data']>(() => ({
    labels: this.svpSales().map((p) => p.label),
    datasets: [
      { label: 'Sales', data: this.svpSales().map((p) => p.amount), backgroundColor: '#277a4b', borderRadius: 6, barThickness: 14 },
      { label: 'Purchases', data: this.svpPurchases().map((p) => p.amount), backgroundColor: '#c57c11', borderRadius: 6, barThickness: 14 }
    ]
  }));

  readonly expensesChartData = computed<ChartConfiguration['data']>(() => {
    const items = this.charts()?.expensesByCategory ?? [];
    return {
      labels: items.map((i) => i.category),
      datasets: [
        {
          data: items.map((i) => i.amount),
          backgroundColor: ['#1f6f43', '#91b982', '#d89a27', '#d8dfd7', '#64766b', '#efbd67', '#b8ccb5', '#355847']
        }
      ]
    };
  });

  readonly topFruits = computed(() => this.charts()?.topSellingFruits ?? []);
  readonly topCustomers = computed(() => this.charts()?.topCustomers ?? []);

  ngOnInit(): void {
    forkJoin({
      summary: this.dashboardService.getSummary(),
      charts: this.dashboardService.getCharts()
    }).subscribe({
      next: ({ summary, charts }) => {
        this.summary.set(summary);
        this.charts.set(charts);
        this.loading.set(false);
      },
      error: () => this.loading.set(false)
    });

    this.loadSalesTrend();
    this.loadSalesVsPurchases();
    this.loadStock();
  }

  stockLevelPercent(item: CurrentStock): number {
    return Math.round((item.currentStock / this.maxStockForBar()) * 100);
  }

  private loadStock(): void {
    this.stockLoading.set(true);
    this.stockService.getCurrentStock().subscribe({
      next: (items) => {
        this.stockItems.set(items);
        this.stockLoading.set(false);
      },
      error: () => this.stockLoading.set(false)
    });
  }

  onSalesPeriodChange(): void {
    this.loadSalesTrend();
  }

  onSvpPeriodChange(): void {
    this.loadSalesVsPurchases();
  }

  private loadSalesTrend(): void {
    this.salesTrendLoading.set(true);
    this.dashboardService.getSalesTrend(this.salesPeriod()).subscribe({
      next: (points) => {
        this.salesTrend.set(points);
        this.salesTrendLoading.set(false);
      },
      error: () => this.salesTrendLoading.set(false)
    });
  }

  private loadSalesVsPurchases(): void {
    this.svpLoading.set(true);
    this.dashboardService.getSalesVsPurchases(this.svpPeriod()).subscribe({
      next: (result) => {
        this.svpSales.set(result.sales);
        this.svpPurchases.set(result.purchases);
        this.svpLoading.set(false);
      },
      error: () => this.svpLoading.set(false)
    });
  }

  private toLineChart(items: { label: string; amount: number }[] | undefined, label: string): ChartConfiguration['data'] {
    const data = items ?? [];
    return {
      labels: data.map((i) => i.label),
      datasets: [
        {
          label,
          data: data.map((i) => i.amount),
          borderColor: '#1f7a48',
          backgroundColor: 'rgba(31, 122, 72, 0.12)',
          fill: true,
          tension: 0.35,
          pointBackgroundColor: '#1f7a48',
          pointBorderColor: '#ffffff',
          pointBorderWidth: 2,
          pointRadius: 3,
          pointHoverRadius: 5
        }
      ]
    };
  }
}
