import { Component, OnInit, inject, signal } from '@angular/core';
import { CurrencyPipe, DatePipe, DecimalPipe } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { MatTabsModule } from '@angular/material/tabs';
import { MatTableModule } from '@angular/material/table';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';
import { MatDatepickerModule } from '@angular/material/datepicker';
import { MatNativeDateModule } from '@angular/material/core';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressBarModule } from '@angular/material/progress-bar';
import { MatCardModule } from '@angular/material/card';
import { ProfitService } from './profit.service';
import { ShopMasterService } from '../shop-master/shop-master.service';
import { ShopMaster } from '../../core/models/master-data.model';
import {
  BusinessProfitTotal,
  FruitProfitSummaryRow,
  ShopDailyProfitRow,
  ShopFruitProfitRow,
  ShopProfitSummaryRow
} from '../../core/models/profit.model';

function firstOfMonth(): Date {
  const now = new Date();
  return new Date(now.getFullYear(), now.getMonth(), 1);
}

function toIso(date: Date): string {
  return date.toISOString().slice(0, 10);
}

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
    MatDatepickerModule,
    MatNativeDateModule,
    MatIconModule,
    MatProgressBarModule,
    MatCardModule
  ],
  templateUrl: './profit.component.html'
})
export class ProfitComponent implements OnInit {
  private readonly profitService = inject(ProfitService);
  private readonly shopService = inject(ShopMasterService);

  fromDate = firstOfMonth();
  toDate = new Date();
  readonly loading = signal(false);
  readonly activeTab = signal(0);
  readonly shops = signal<ShopMaster[]>([]);
  selectedShopId: number | null = null;

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

  loadActiveTab(): void {
    const from = toIso(this.fromDate);
    const to = toIso(this.toDate);
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
      case 1:
        this.profitService.getShopProfitSummary(from, to).subscribe({
          next: (r) => {
            this.shopSummary.set(r);
            finish();
          },
          error: finish
        });
        if (this.selectedShopId) {
          this.profitService.getShopDailyProfit(this.selectedShopId, from, to).subscribe((r) => this.shopDaily.set(r));
        } else {
          this.shopDaily.set([]);
        }
        break;
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
