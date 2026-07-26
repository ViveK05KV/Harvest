import { Component, OnInit, computed, inject, signal } from '@angular/core';
import { CurrencyPipe } from '@angular/common';
import { MatCardModule } from '@angular/material/card';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { ChartConfiguration } from 'chart.js';
import { forkJoin } from 'rxjs';
import { ChartComponent } from '../../shared/chart/chart.component';
import { DashboardService } from './dashboard.service';
import { DashboardCharts, DashboardSummary } from '../../core/models/dashboard.model';

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
  imports: [CurrencyPipe, MatCardModule, MatIconModule, MatProgressSpinnerModule, ChartComponent],
  templateUrl: './dashboard.component.html',
  styleUrl: './dashboard.component.scss'
})
export class DashboardComponent implements OnInit {
  private readonly dashboardService = inject(DashboardService);

  readonly loading = signal(true);
  readonly summary = signal<DashboardSummary | null>(null);
  readonly charts = signal<DashboardCharts | null>(null);

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

  readonly salesChartData = computed<ChartConfiguration['data']>(() => this.toLineChart(this.charts()?.salesByMonth, 'Sales'));
  readonly collectionsChartData = computed<ChartConfiguration['data']>(() =>
    this.toLineChart(this.charts()?.collectionsByMonth, 'Collections')
  );

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
  }

  private toLineChart(items: { month: string; amount: number }[] | undefined, label: string): ChartConfiguration['data'] {
    const data = items ?? [];
    return {
      labels: data.map((i) => i.month),
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
