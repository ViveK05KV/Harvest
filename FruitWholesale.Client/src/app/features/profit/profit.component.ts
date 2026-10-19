import { Component, OnInit, computed, inject, signal } from '@angular/core';
import { forkJoin, of } from 'rxjs';
import { CurrencyPipe, DatePipe, DecimalPipe } from '@angular/common';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressBarModule } from '@angular/material/progress-bar';
import { ProfitService } from './profit.service';
import { ShopMasterService } from '../shop-master/shop-master.service';
import { DashboardService } from '../dashboard/dashboard.service';
import { ShopMaster } from '../../core/models/master-data.model';
import { toIso } from '../../core/utils/date.util';

// No purchase/sale history exists before this date - only opening shop/supplier
// balances were carried forward, so profit reporting is scoped to this date
// onward everywhere (matches ProfitConstants.TrackingStartDate on the backend).
const PROFIT_TRACKING_START_DATE = new Date(2026, 7, 1);
import {
  BusinessDailyProfitRow,
  ActualProfitRow,
  BusinessProfitTotal,
  FruitProfitSummaryRow,
  ShopDailyProfitRow,
  ShopFruitProfitRow,
  ShopProfitSummaryRow
} from '../../core/models/profit.model';

@Component({
  selector: 'app-profit',
  standalone: true,
  imports: [CurrencyPipe, DatePipe, DecimalPipe, MatIconModule, MatProgressBarModule],
  templateUrl: './profit.component.html',
  styleUrl: './profit.component.scss'
})
export class ProfitComponent implements OnInit {
  private readonly profitService = inject(ProfitService);
  private readonly shopService = inject(ShopMasterService);
  private readonly dashboardService = inject(DashboardService);

  fromDate = toIso(PROFIT_TRACKING_START_DATE);
  toDate = toIso(new Date());
  readonly minProfitDateStr = toIso(PROFIT_TRACKING_START_DATE);
  readonly loading = signal(false);
  readonly activeTab = signal(0);
  readonly profitRange = signal<'week' | 'month' | 'year' | 'custom'>('month');
  readonly actualRange = signal<'today' | 'week' | 'month' | 'year' | 'custom'>('today');
  readonly shops = signal<ShopMaster[]>([]);
  tillToday = false;
  selectedShopId: number | null = null;

  readonly businessTotal = signal<BusinessProfitTotal | null>(null);
  readonly netBusinessWorth = signal<number | null>(null);
  readonly shopSummary = signal<ShopProfitSummaryRow[]>([]);
  readonly shopDaily = signal<ShopDailyProfitRow[]>([]);
  readonly fruitSummary = signal<FruitProfitSummaryRow[]>([]);
  readonly shopFruit = signal<ShopFruitProfitRow[]>([]);
  readonly businessDaily = signal<BusinessDailyProfitRow[]>([]);
  readonly actualProfit = signal<ActualProfitRow[]>([]);
  readonly actualProfitSort = signal<{ key: keyof ActualProfitRow; direction: 'asc' | 'desc' }>({ key: 'date', direction: 'desc' });
  readonly sortedActualProfit = computed(() => {
    const { key, direction } = this.actualProfitSort();
    const multiplier = direction === 'asc' ? 1 : -1;
    return [...this.actualProfit()].sort((a, b) => {
      const left = a[key];
      const right = b[key];
      const difference = key === 'date'
        ? new Date(String(left)).getTime() - new Date(String(right)).getTime()
        : typeof left === 'string' || typeof right === 'string'
          ? String(left ?? '').localeCompare(String(right ?? ''))
          : Number(left) - Number(right);
      return difference * multiplier;
    });
  });
  readonly profitSort = signal<{ key: keyof BusinessDailyProfitRow; direction: 'asc' | 'desc' }>({ key: 'date', direction: 'desc' });
  readonly sortedBusinessDaily = computed(() => {
    const { key, direction } = this.profitSort();
    const multiplier = direction === 'asc' ? 1 : -1;
    return [...this.businessDaily()].sort((a, b) => {
      const difference = key === 'date'
        ? new Date(a.date).getTime() - new Date(b.date).getTime()
        : Number(a[key]) - Number(b[key]);
      return difference * multiplier;
    });
  });

  private loadRequestId = 0;

  ngOnInit(): void {
    this.shopService.getAllActive().subscribe((shops) => this.shops.set(shops));
    this.loadActiveTab();
  }

  onTabChange(index: number): void {
    this.activeTab.set(index);
    if (index === 4) this.setProfitRange(this.profitRange());
    else if (index === 5) this.setActualRange(this.actualRange());
    else this.loadActiveTab();
  }

  setActualRange(range: 'today' | 'week' | 'month' | 'year' | 'custom'): void {
    this.actualRange.set(range);
    if (range !== 'custom') {
      const today = new Date();
      const to = new Date(today.getFullYear(), today.getMonth(), today.getDate());
      const from = new Date(to);
      if (range === 'week') from.setDate(from.getDate() - 6);
      else if (range === 'month') from.setMonth(from.getMonth() - 1);
      else if (range === 'year') from.setFullYear(from.getFullYear() - 1);
      this.fromDate = toIso(from < PROFIT_TRACKING_START_DATE ? PROFIT_TRACKING_START_DATE : from);
      this.toDate = toIso(to);
    }
    this.loadActiveTab();
  }

  sortActualProfitBy(key: keyof ActualProfitRow): void {
    const current = this.actualProfitSort();
    this.actualProfitSort.set({ key, direction: current.key === key && current.direction === 'desc' ? 'asc' : 'desc' });
  }

  setProfitRange(range: 'week' | 'month' | 'year' | 'custom'): void {
    this.profitRange.set(range);
    if (range !== 'custom') {
      const today = new Date();
      const from = new Date(today.getFullYear(), today.getMonth(), today.getDate());
      if (range === 'week') {
        from.setDate(from.getDate() - 6);
      } else if (range === 'month') {
        const day = from.getDate();
        from.setDate(1);
        from.setMonth(from.getMonth() - 1);
        from.setDate(Math.min(day, new Date(from.getFullYear(), from.getMonth() + 1, 0).getDate()));
      } else {
        const day = from.getDate();
        from.setDate(1);
        from.setFullYear(from.getFullYear() - 1);
        from.setDate(Math.min(day, new Date(from.getFullYear(), from.getMonth() + 1, 0).getDate()));
      }
      this.fromDate = toIso(from < PROFIT_TRACKING_START_DATE ? PROFIT_TRACKING_START_DATE : from);
      this.toDate = toIso(today);
    }
    this.loadActiveTab();
  }

  sortProfitBy(key: keyof BusinessDailyProfitRow): void {
    const current = this.profitSort();
    this.profitSort.set({ key, direction: current.key === key && current.direction === 'desc' ? 'asc' : 'desc' });
  }

  onFilterChange(): void {
    this.loadActiveTab();
  }

  onShopChange(value: string): void {
    this.selectedShopId = value ? Number(value) : null;
    this.onFilterChange();
  }

  setTillToday(value: boolean): void {
    this.tillToday = value;
    this.loadActiveTab();
  }

  loadActiveTab(): void {
    const useAllTime = this.tillToday && (this.activeTab() === 1 || this.activeTab() === 2);
    const from = useAllTime ? toIso(PROFIT_TRACKING_START_DATE) : this.fromDate;
    const to = useAllTime ? undefined : this.toDate;
    this.loading.set(true);

    // A stale response from a previous tab/filter must not overwrite a newer
    // one's data or flip loading false while a newer request is still pending.
    const requestId = ++this.loadRequestId;
    const isStale = () => requestId !== this.loadRequestId;
    const finish = () => {
      if (!isStale()) this.loading.set(false);
    };

    switch (this.activeTab()) {
      case 0:
        forkJoin({ total: this.profitService.getBusinessTotalProfit(), summary: this.dashboardService.getSummary() }).subscribe({
          next: ({ total, summary }) => {
            if (isStale()) return;
            this.businessTotal.set(total);
            this.netBusinessWorth.set(summary.netBusinessWorth);
            finish();
          },
          error: finish
        });
        break;
      case 1: {
        const shopDaily$ = this.selectedShopId
          ? this.profitService.getShopDailyProfit(this.selectedShopId, from, to)
          : of<ShopDailyProfitRow[]>([]);
        forkJoin({ summary: this.profitService.getShopProfitSummary(from, to), daily: shopDaily$ }).subscribe({
          next: ({ summary, daily }) => {
            if (isStale()) return;
            this.shopSummary.set(summary);
            this.shopDaily.set(daily);
            finish();
          },
          error: finish
        });
        break;
      }
      case 2:
        this.profitService.getFruitProfitSummary(from, to).subscribe({
          next: (r) => {
            if (isStale()) return;
            this.fruitSummary.set(r);
            finish();
          },
          error: finish
        });
        break;
      case 3:
        this.profitService.getShopFruitProfit(this.selectedShopId, from, to).subscribe({
          next: (r) => {
            if (isStale()) return;
            this.shopFruit.set(r);
            finish();
          },
          error: finish
        });
        break;
      case 4:
        this.profitService.getBusinessDailyProfit(this.fromDate, this.toDate).subscribe({
          next: (rows) => {
            if (isStale()) return;
            this.businessDaily.set(rows);
            finish();
          },
          error: finish
        });
        break;
      case 5:
        this.profitService.getActualProfit(this.selectedShopId, this.fromDate, this.toDate).subscribe({
          next: (rows) => {
            if (isStale()) return;
            this.actualProfit.set(rows);
            finish();
          },
          error: finish
        });
        break;
    }
  }
}
