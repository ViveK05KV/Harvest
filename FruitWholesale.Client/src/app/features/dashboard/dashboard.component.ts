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
    return [
      { label: 'Current Cash Balance', value: s.currentCashBalance, icon: 'account_balance_wallet' },
      { label: "Today's Collection", value: s.todayCollection, icon: 'payments' },
      { label: "Today's Sales", value: s.todaySales, icon: 'point_of_sale' },
      { label: "Today's Purchases", value: s.todayPurchases, icon: 'shopping_cart' },
      { label: "Today's Expenses", value: s.todayExpenses, icon: 'receipt_long' },
      { label: 'Customer Outstanding', value: s.customerOutstanding, icon: 'storefront' },
      { label: 'Supplier Outstanding', value: s.supplierOutstanding, icon: 'local_shipping' },
      { label: 'Net Business Worth', value: s.netBusinessWorth, icon: 'trending_up', emphasis: true }
    ];
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
          backgroundColor: ['#1565c0', '#3b7dc4', '#5c94d1', '#8bb4de', '#ef6c00', '#f7913f', '#fab066', '#fdd0a2']
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
          borderColor: '#1565c0',
          backgroundColor: 'rgba(21, 101, 192, 0.15)',
          fill: true,
          tension: 0.3
        }
      ]
    };
  }
}
