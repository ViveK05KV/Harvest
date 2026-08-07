import { Component, OnInit, inject, signal } from '@angular/core';
import { forkJoin, of } from 'rxjs';
import { CurrencyPipe, DatePipe, DecimalPipe } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { MatTabsModule } from '@angular/material/tabs';
import { MatTableModule } from '@angular/material/table';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';
import { MatAutocompleteModule, MatAutocompleteSelectedEvent } from '@angular/material/autocomplete';
import { MatDatepickerModule } from '@angular/material/datepicker';
import { MatNativeDateModule } from '@angular/material/core';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressBarModule } from '@angular/material/progress-bar';
import { MatCardModule } from '@angular/material/card';
import { MatButtonToggleModule } from '@angular/material/button-toggle';
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
  imports: [
    CurrencyPipe,
    DatePipe,
    DecimalPipe,
    FormsModule,
    MatTabsModule,
    MatTableModule,
    MatFormFieldModule,
    MatInputModule,
    MatSelectModule,
    MatAutocompleteModule,
    MatDatepickerModule,
    MatNativeDateModule,
    MatIconModule,
    MatProgressBarModule,
    MatCardModule,
    MatButtonToggleModule
  ],
  templateUrl: './profit.component.html'
})
export class ProfitComponent implements OnInit {
  private readonly profitService = inject(ProfitService);
  private readonly shopService = inject(ShopMasterService);

  fromDate = PROFIT_TRACKING_START_DATE;
  toDate = new Date();
  readonly minProfitDate = PROFIT_TRACKING_START_DATE;
  readonly loading = signal(false);
  readonly activeTab = signal(0);
  readonly shops = signal<ShopMaster[]>([]);
  tillToday = false;
  selectedShopId: number | null = null;
  selectedShopSearch = '';

  readonly businessTotal = signal<BusinessProfitTotal | null>(null);
  readonly shopSummary = signal<ShopProfitSummaryRow[]>([]);
  readonly shopDaily = signal<ShopDailyProfitRow[]>([]);
  readonly fruitSummary = signal<FruitProfitSummaryRow[]>([]);
  readonly shopFruit = signal<ShopFruitProfitRow[]>([]);

  readonly shopSummaryColumns = ['shopName', 'revenue', 'cost', 'profit', 'marginPercent'];
  readonly shopDailyColumns = ['date', 'revenue', 'cost', 'profit', 'marginPercent'];
  readonly fruitSummaryColumns = ['fruitName', 'quantitySold', 'revenue', 'cost', 'profit', 'marginPercent'];
  readonly shopFruitColumns = ['shopName', 'fruitName', 'quantitySold', 'revenue', 'cost', 'profit', 'marginPercent'];

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

  filteredShops(search: string | null | undefined): ShopMaster[] {
    const term = (search ?? '').trim().toLowerCase();
    if (!term) return this.shops();
    return this.shops().filter((s) => s.shopName.toLowerCase().includes(term));
  }

  readonly displayShop = (value: unknown): string =>
    typeof value === 'number' ? (this.shops().find((s) => s.shopID === value)?.shopName ?? '') : typeof value === 'string' ? value : '';

  onSelectedShopFilterSelected(event: MatAutocompleteSelectedEvent): void {
    const shopId = event.option.value as number | null;
    this.selectedShopId = shopId;
    this.selectedShopSearch = shopId == null ? '' : (this.shops().find((s) => s.shopID === shopId)?.shopName ?? '');
    this.onFilterChange();
  }

  onSelectedShopSearchFocus(): void {
    if (this.selectedShopSearch === (this.shops().find((s) => s.shopID === this.selectedShopId)?.shopName ?? '')) {
      this.selectedShopSearch = '';
    }
  }

  // Typing away from the settled shop name must clear the stale filter and
  // reload - otherwise the field shows different text while the table silently
  // stays filtered by whatever shop was previously selected.
  onSelectedShopSearchInput(): void {
    this.selectedShopId = null;
    this.onFilterChange();
  }

  onTillTodayChange(): void {
    this.loadActiveTab();
  }

  loadActiveTab(): void {
    const useAllTime = this.tillToday && (this.activeTab() === 1 || this.activeTab() === 2);
    const from = useAllTime ? toIso(PROFIT_TRACKING_START_DATE) : toIso(this.fromDate);
    const to = useAllTime ? undefined : toIso(this.toDate);
    this.loading.set(true);

    const finish = () => this.loading.set(false);

    switch (this.activeTab()) {
      case 0:
        this.profitService.getBusinessTotalProfit().subscribe({
          next: (r) => {
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
            this.fruitSummary.set(r);
            finish();
          },
          error: finish
        });
        break;
      case 3:
        this.profitService.getShopFruitProfit(this.selectedShopId, from, to).subscribe({
          next: (r) => {
            this.shopFruit.set(r);
            finish();
          },
          error: finish
        });
        break;
    }
  }
}
