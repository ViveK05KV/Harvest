import { ChangeDetectionStrategy, Component, OnInit, computed, inject, signal } from '@angular/core';
import { CurrencyPipe, DatePipe } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { MatCardModule } from '@angular/material/card';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { ChartConfiguration } from 'chart.js';
import { forkJoin } from 'rxjs';
import { ChartComponent } from '../../shared/chart/chart.component';
import { DashboardService } from './dashboard.service';
import { AuthService } from '../../core/services/auth.service';
import { ShopMasterService } from '../shop-master/shop-master.service';
import { SupplierMasterService } from '../supplier-master/supplier-master.service';
import {
  DASHBOARD_PERIODS,
  DASHBOARD_PERIOD_LABELS,
  DashboardCharts,
  DashboardPeriod,
  DashboardSummary,
  TrendPoint
} from '../../core/models/dashboard.model';

interface PayableRow {
  name: string;
  amount: number;
}

interface TodayStripTile {
  label: string;
  value: number;
}

const SPARKLINE_OPTIONS: ChartConfiguration['options'] = {
  scales: { x: { display: false }, y: { display: false } },
  plugins: { legend: { display: false }, tooltip: { enabled: false } },
  elements: { point: { radius: 0 } }
};

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [
    CurrencyPipe,
    DatePipe,
    FormsModule,
    MatCardModule,
    MatIconModule,
    MatProgressSpinnerModule,
    ChartComponent
  ],
  templateUrl: './dashboard.component.html',
  styleUrl: './dashboard.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class DashboardComponent implements OnInit {
  private readonly dashboardService = inject(DashboardService);
  private readonly shopMasterService = inject(ShopMasterService);
  private readonly supplierMasterService = inject(SupplierMasterService);
  readonly authService = inject(AuthService);

  readonly sparklineOptions = SPARKLINE_OPTIONS;
  readonly today = new Date();
  readonly isBackOffice = computed(() => this.authService.hasRole('Admin', 'Manager', 'Accountant'));

  readonly loading = signal(true);
  readonly summary = signal<DashboardSummary | null>(null);
  readonly charts = signal<DashboardCharts | null>(null);

  readonly periodOptions = DASHBOARD_PERIODS;
  readonly periodLabel = (period: DashboardPeriod) => DASHBOARD_PERIOD_LABELS[period];

  readonly svpPeriod = signal<DashboardPeriod>('ThisWeek');
  readonly svpLoading = signal(true);
  readonly svpSales = signal<TrendPoint[]>([]);
  readonly svpPurchases = signal<TrendPoint[]>([]);
  private svpRequestId = 0;

  readonly cashTrend = signal<TrendPoint[]>([]);
  readonly profitTrend = signal<TrendPoint[]>([]);

  readonly cashTrendRange = computed(() => {
    const points = this.cashTrend();
    return { start: points[0]?.label ?? '', end: points[points.length - 1]?.label ?? '', days: points.length };
  });

  readonly payables = signal<PayableRow[]>([]);
  readonly supplierCount = signal(0);
  readonly shopsWithBalanceCount = signal(0);
  readonly overLimitAmount = signal(0);
  readonly overLimitShopCount = signal(0);

  readonly todayStrip = computed<TodayStripTile[]>(() => {
    const s = this.summary();
    if (!s) return [];
    const tiles: TodayStripTile[] = [
      { label: 'Sales', value: s.todaySales },
      { label: 'Collections', value: s.todayCollection },
      { label: 'Purchases', value: s.todayPurchases },
      { label: 'Expenses', value: s.todayExpenses }
    ];
    if (s.todayProfit !== null) {
      tiles.push({ label: 'Profit', value: s.todayProfit });
    }
    tiles.push({ label: 'Net Cash', value: s.todayCollection - s.todayPurchases - s.todayExpenses });
    return tiles;
  });

  readonly customerAtRiskPercent = computed(() => {
    const s = this.summary();
    if (!s || s.customerOutstanding <= 0) return 0;
    return Math.min(100, Math.round((this.overLimitAmount() / s.customerOutstanding) * 100));
  });

  readonly cashSparklineData = computed<ChartConfiguration['data']>(() => this.toSparkline(this.cashTrend(), '#7fd6a0'));
  readonly profitSparklineData = computed<ChartConfiguration['data']>(() => this.toSparkline(this.profitTrend(), '#1c6b45'));

  readonly svpChartOptions: ChartConfiguration['options'] = {
    plugins: { legend: { display: false } },
    scales: {
      x: { grid: { display: false }, border: { display: false } },
      y: { display: false, grid: { display: false } }
    }
  };

  readonly salesVsPurchasesData = computed<ChartConfiguration['data']>(() => {
    const sales = this.svpSales();
    const purchases = this.svpPurchases();
    return {
      labels: sales.map((p) => p.label),
      datasets: [
        { label: 'Sales', data: sales.map((p) => p.amount), backgroundColor: '#1c6b45', borderRadius: 6, barThickness: 14 },
        { label: 'Purchases', data: purchases.map((p) => p.amount), backgroundColor: '#c3d4c8', borderRadius: 6, barThickness: 14 }
      ]
    };
  });

  readonly periodTotals = computed(() => {
    const sales = this.svpSales().reduce((sum, p) => sum + p.amount, 0);
    const purchases = this.svpPurchases().reduce((sum, p) => sum + p.amount, 0);
    return { sales, purchases, margin: sales - purchases };
  });

  private readonly expensePalette = ['#1c6b45', '#7fa88f', '#c99a3d', '#c3d4c8', '#5f7a6a', '#efbd67', '#a8c4b0', '#3c453f'];

  readonly expensesChartData = computed<ChartConfiguration['data']>(() => {
    const items = this.charts()?.expensesByCategory ?? [];
    return {
      labels: items.map((i) => i.category),
      datasets: [
        {
          data: items.map((i) => i.amount),
          backgroundColor: items.map((_, idx) => this.expensePalette[idx % this.expensePalette.length]),
          borderWidth: 0
        }
      ]
    };
  });

  readonly doughnutOptions: ChartConfiguration['options'] = {
    cutout: '72%',
    plugins: { legend: { display: false }, tooltip: { enabled: true } }
  } as ChartConfiguration['options'];

  readonly spendTotal = computed(() => (this.charts()?.expensesByCategory ?? []).reduce((sum, i) => sum + i.amount, 0));

  readonly spendBreakdown = computed(() => {
    const items = this.charts()?.expensesByCategory ?? [];
    const total = this.spendTotal() || 1;
    return items.map((i, idx) => ({
      category: i.category,
      amount: i.amount,
      pct: Math.round((i.amount / total) * 100),
      color: this.expensePalette[idx % this.expensePalette.length]
    }));
  });

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

    this.loadSalesVsPurchases();
    this.loadCashTrend();
    this.loadProfitTrend();
    this.loadPayables();
    this.loadCustomerRisk();
  }

  onSvpPeriodChange(): void {
    this.loadSalesVsPurchases();
  }

  private loadSalesVsPurchases(): void {
    this.svpLoading.set(true);
    // Guard against a slower, stale-period response landing after a newer one -
    // switching the period dropdown quickly must not let an older response overwrite it.
    const requestId = ++this.svpRequestId;
    this.dashboardService.getSalesVsPurchases(this.svpPeriod()).subscribe({
      next: (result) => {
        if (requestId !== this.svpRequestId) return;
        this.svpSales.set(result.sales);
        this.svpPurchases.set(result.purchases);
        this.svpLoading.set(false);
      },
      error: () => {
        if (requestId !== this.svpRequestId) return;
        this.svpLoading.set(false);
      }
    });
  }

  private loadCashTrend(): void {
    this.dashboardService.getCashTrend().subscribe({ next: (points) => this.cashTrend.set(points) });
  }

  private loadProfitTrend(): void {
    this.dashboardService.getProfitTrend().subscribe({ next: (points) => this.profitTrend.set(points) });
  }

  private loadPayables(): void {
    this.supplierMasterService.getAllActive().subscribe({
      next: (suppliers) => {
        const withBalance = suppliers.filter((s) => s.currentOutstanding > 0);
        this.supplierCount.set(withBalance.length);
        this.payables.set(
          [...withBalance]
            .sort((a, b) => b.currentOutstanding - a.currentOutstanding)
            .slice(0, 3)
            .map((s) => ({ name: s.supplierName, amount: s.currentOutstanding }))
        );
      }
    });
  }

  private loadCustomerRisk(): void {
    this.shopMasterService.getAllActive().subscribe({
      next: (shops) => {
        this.shopsWithBalanceCount.set(shops.filter((s) => s.currentOutstanding > 0).length);
        const overLimit = shops.filter((s) => s.creditLimit > 0 && s.currentOutstanding > s.creditLimit);
        this.overLimitShopCount.set(overLimit.length);
        this.overLimitAmount.set(overLimit.reduce((sum, s) => sum + (s.currentOutstanding - s.creditLimit), 0));
      }
    });
  }

  private toSparkline(points: TrendPoint[], color: string): ChartConfiguration['data'] {
    return {
      labels: points.map((p) => p.label),
      datasets: [
        {
          data: points.map((p) => p.amount),
          backgroundColor: color,
          borderRadius: 3
        }
      ]
    };
  }
}
