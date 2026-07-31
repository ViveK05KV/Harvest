import { ChangeDetectionStrategy, Component, OnInit, computed, inject, signal } from '@angular/core';
import { CurrencyPipe, DatePipe, DecimalPipe } from '@angular/common';
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
import { AuthService } from '../../core/services/auth.service';
import { ShopMasterService } from '../shop-master/shop-master.service';
import { SupplierMasterService } from '../supplier-master/supplier-master.service';
import { LedgerService } from '../ledgers/ledger.service';
import { cashLedgerTypeLabel } from '../../core/models/ledger.model';
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

interface CashTapeRow {
  time: string;
  label: string;
  note: string;
  amount: number;
  isIn: boolean;
  balance: number;
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
    DecimalPipe,
    FormsModule,
    RouterLink,
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
  private readonly stockService = inject(StockService);
  private readonly shopMasterService = inject(ShopMasterService);
  private readonly supplierMasterService = inject(SupplierMasterService);
  private readonly ledgerService = inject(LedgerService);
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

  readonly cashTrend = signal<TrendPoint[]>([]);
  readonly profitTrend = signal<TrendPoint[]>([]);

  readonly payables = signal<PayableRow[]>([]);
  readonly supplierCount = signal(0);
  readonly shopsWithBalanceCount = signal(0);
  readonly overLimitAmount = signal(0);
  readonly overLimitShopCount = signal(0);

  readonly cashTapeLoading = signal(true);
  readonly cashTape = signal<CashTapeRow[]>([]);

  readonly todayStrip = computed<TodayStripTile[]>(() => {
    const s = this.summary();
    if (!s) return [];
    return [
      { label: 'Sales', value: s.todaySales },
      { label: 'Collections', value: s.todayCollection },
      { label: 'Purchases', value: s.todayPurchases },
      { label: 'Expenses', value: s.todayExpenses },
      { label: 'Net Cash', value: s.todayCollection - s.todayPurchases - s.todayExpenses }
    ];
  });

  readonly todayMarginPercent = computed(() => {
    const s = this.summary();
    if (!s || !s.todayProfit || !s.todaySales) return null;
    return (s.todayProfit / s.todaySales) * 100;
  });

  readonly customerAtRiskPercent = computed(() => {
    const s = this.summary();
    if (!s || s.customerOutstanding <= 0) return 0;
    return Math.min(100, Math.round((this.overLimitAmount() / s.customerOutstanding) * 100));
  });

  readonly cashSparklineData = computed<ChartConfiguration['data']>(() => this.toSparkline(this.cashTrend(), '#7fd6a0'));
  readonly profitSparklineData = computed<ChartConfiguration['data']>(() => this.toSparkline(this.profitTrend(), '#1f7a48'));

  readonly stockLoading = signal(true);
  readonly stockItems = signal<CurrentStock[]>([]);
  readonly lowStockItems = computed(() => [...this.stockItems()].sort((a, b) => a.currentStock - b.currentStock).slice(0, 6));
  readonly maxStockForBar = computed(() => Math.max(1, ...this.stockItems().map((i) => i.currentStock)));

  readonly salesVsPurchasesMarginData = computed<ChartConfiguration['data']>(() => {
    const sales = this.svpSales();
    const purchases = this.svpPurchases();
    return {
      labels: sales.map((p) => p.label),
      datasets: [
        { type: 'bar' as const, label: 'Sales', data: sales.map((p) => p.amount), backgroundColor: '#277a4b', borderRadius: 6, barThickness: 14 },
        {
          type: 'bar' as const,
          label: 'Purchases',
          data: purchases.map((p) => p.amount),
          backgroundColor: '#c57c11',
          borderRadius: 6,
          barThickness: 14
        },
        {
          type: 'line' as const,
          label: 'Margin',
          data: sales.map((p, i) => p.amount - (purchases[i]?.amount ?? 0)),
          borderColor: '#1f7a48',
          backgroundColor: '#1f7a48',
          tension: 0.35,
          pointRadius: 3,
          pointBackgroundColor: '#1f7a48'
        }
      ]
    };
  });

  readonly periodTotals = computed(() => {
    const sales = this.svpSales().reduce((sum, p) => sum + p.amount, 0);
    const purchases = this.svpPurchases().reduce((sum, p) => sum + p.amount, 0);
    return { sales, purchases, margin: sales - purchases };
  });

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
    this.loadStock();
    this.loadCashTrend();
    this.loadProfitTrend();
    this.loadPayables();
    this.loadCustomerRisk();
    this.loadCashTape();
  }

  stockLevelPercent(item: CurrentStock): number {
    return Math.round((item.currentStock / this.maxStockForBar()) * 100);
  }

  onSvpPeriodChange(): void {
    this.loadSalesVsPurchases();
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

  private loadCashTape(): void {
    this.cashTapeLoading.set(true);
    const todayStr = new Date().toISOString().slice(0, 10);
    this.ledgerService.getCashLedger({ pageNumber: 1, pageSize: 50 }, todayStr, todayStr).subscribe({
      next: (result) => {
        this.cashTape.set(
          [...result.items]
            .reverse()
            .slice(0, 8)
            .map((entry) => ({
              time: new Date(entry.transactionDate).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
              label: cashLedgerTypeLabel(entry.transactionType),
              note: entry.narration ?? entry.paymentMode,
              amount: entry.cashIn > 0 ? entry.cashIn : entry.cashOut,
              isIn: entry.cashIn > 0,
              balance: entry.runningBalance
            }))
        );
        this.cashTapeLoading.set(false);
      },
      error: () => this.cashTapeLoading.set(false)
    });
  }

  private toSparkline(points: TrendPoint[], color: string): ChartConfiguration['data'] {
    return {
      labels: points.map((p) => p.label),
      datasets: [
        {
          data: points.map((p) => p.amount),
          borderColor: color,
          backgroundColor: color + '33',
          fill: true,
          tension: 0.35,
          borderWidth: 2
        }
      ]
    };
  }
}
