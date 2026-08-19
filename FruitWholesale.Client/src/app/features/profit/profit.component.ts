import { Component, OnInit, inject, signal } from '@angular/core';
import { forkJoin, of } from 'rxjs';
import { CurrencyPipe, DatePipe, DecimalPipe } from '@angular/common';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressBarModule } from '@angular/material/progress-bar';
import { ProfitService } from './profit.service';
import { ShopMasterService } from '../shop-master/shop-master.service';
import { ShopMaster } from '../../core/models/master-data.model';
import { toIso } from '../../core/utils/date.util';

// No purchase/sale history exists before this date - only opening shop/supplier
// balances were carried forward, so profit reporting is scoped to this date
// onward everywhere (matches ProfitConstants.TrackingStartDate on the backend).
const PROFIT_TRACKING_START_DATE = new Date(2026, 7, 1);
import {
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

  fromDate = toIso(PROFIT_TRACKING_START_DATE);
  toDate = toIso(new Date());
  readonly minProfitDateStr = toIso(PROFIT_TRACKING_START_DATE);
  readonly loading = signal(false);
  readonly activeTab = signal(0);
  readonly shops = signal<ShopMaster[]>([]);
  tillToday = false;
  selectedShopId: number | null = null;

  readonly businessTotal = signal<BusinessProfitTotal | null>(null);
  readonly shopSummary = signal<ShopProfitSummaryRow[]>([]);
  readonly shopDaily = signal<ShopDailyProfitRow[]>([]);
  readonly fruitSummary = signal<FruitProfitSummaryRow[]>([]);
  readonly shopFruit = signal<ShopFruitProfitRow[]>([]);

  private loadRequestId = 0;

  ngOnInit(): void {
    this.shopService.getAllActive().subscribe((shops) => this.shops.set(shops));
    this.loadActiveTab();
  }

  onTabChange(index: number): void {
    this.activeTab.set(index);
    this.loadActiveTab();
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
        this.profitService.getBusinessTotalProfit().subscribe({
          next: (r) => {
            if (isStale()) return;
            this.businessTotal.set(r);
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
    }
  }
}
