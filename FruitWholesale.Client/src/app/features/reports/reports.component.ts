import { Component, OnInit, inject, signal } from '@angular/core';
import { CurrencyPipe, DatePipe, DecimalPipe } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { MatTabsModule } from '@angular/material/tabs';
import { MatTableModule } from '@angular/material/table';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatDatepickerModule } from '@angular/material/datepicker';
import { MatNativeDateModule } from '@angular/material/core';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressBarModule } from '@angular/material/progress-bar';
import { ReportService } from './report.service';
import { ExportService } from '../../core/services/export.service';
import {
  DailyCollectionReportRow,
  DailyExpenseReportRow,
  DailySalesReportRow,
  FruitSalesReportRow,
  OutstandingReportRow,
  ProfitSummaryReportRow,
  PurchaseReportRow
} from '../../core/models/report.model';

function firstOfMonth(): Date {
  const now = new Date();
  return new Date(now.getFullYear(), now.getMonth(), 1);
}

function toIso(date: Date): string {
  return date.toISOString().slice(0, 10);
}

@Component({
  selector: 'app-reports',
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
    MatDatepickerModule,
    MatNativeDateModule,
    MatButtonModule,
    MatIconModule,
    MatProgressBarModule
  ],
  templateUrl: './reports.component.html'
})
export class ReportsComponent implements OnInit {
  private readonly reportService = inject(ReportService);
  private readonly exportService = inject(ExportService);

  fromDate = firstOfMonth();
  toDate = new Date();
  readonly loading = signal(false);
  readonly activeTab = signal(0);

  readonly dailySales = signal<DailySalesReportRow[]>([]);
  readonly dailyCollection = signal<DailyCollectionReportRow[]>([]);
  readonly dailyExpense = signal<DailyExpenseReportRow[]>([]);
  readonly purchaseReport = signal<PurchaseReportRow[]>([]);
  readonly fruitSales = signal<FruitSalesReportRow[]>([]);
  readonly outstanding = signal<OutstandingReportRow[]>([]);
  readonly profitSummary = signal<ProfitSummaryReportRow[]>([]);

  readonly dailySalesColumns = ['supplyDate', 'invoiceNo', 'shopName', 'totalAmount'];
  readonly dailyCollectionColumns = ['collectionDate', 'shopName', 'amountReceived', 'paymentMode'];
  readonly dailyExpenseColumns = ['expenseDate', 'categoryName', 'paidTo', 'amount', 'paymentMode'];
  readonly purchaseColumns = ['purchaseDate', 'invoiceNo', 'supplierName', 'totalAmount'];
  readonly fruitSalesColumns = ['fruitName', 'unit', 'totalQuantity', 'totalAmount'];
  readonly outstandingColumns = ['type', 'name', 'outstandingAmount'];
  readonly profitColumns = ['month', 'totalSales', 'totalPurchases', 'totalExpenses', 'netProfit'];

  ngOnInit(): void {
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
        this.reportService.getDailySales(from, to).subscribe({
          next: (r) => {
            this.dailySales.set(r);
            finish();
          },
          error: finish
        });
        break;
      case 1:
        this.reportService.getDailyCollection(from, to).subscribe({
          next: (r) => {
            this.dailyCollection.set(r);
            finish();
          },
          error: finish
        });
        break;
      case 2:
        this.reportService.getDailyExpense(from, to).subscribe({
          next: (r) => {
            this.dailyExpense.set(r);
            finish();
          },
          error: finish
        });
        break;
      case 3:
        this.reportService.getPurchaseReport(from, to).subscribe({
          next: (r) => {
            this.purchaseReport.set(r);
            finish();
          },
          error: finish
        });
        break;
      case 4:
        this.reportService.getFruitSales(from, to).subscribe({
          next: (r) => {
            this.fruitSales.set(r);
            finish();
          },
          error: finish
        });
        break;
      case 5:
        this.reportService.getOutstanding().subscribe({
          next: (r) => {
            this.outstanding.set(r);
            finish();
          },
          error: finish
        });
        break;
      case 6:
        this.reportService.getProfitSummary(from, to).subscribe({
          next: (r) => {
            this.profitSummary.set(r);
            finish();
          },
          error: finish
        });
        break;
    }
  }

  exportExcel(): void {
    switch (this.activeTab()) {
      case 0:
        this.exportService.exportToExcel(
          this.dailySales(),
          [
            { header: 'Date', field: 'supplyDate' },
            { header: 'Invoice No', field: 'invoiceNo' },
            { header: 'Shop', field: 'shopName' },
            { header: 'Amount', field: 'totalAmount' }
          ],
          'daily-sales-report'
        );
        break;
      case 1:
        this.exportService.exportToExcel(
          this.dailyCollection(),
          [
            { header: 'Date', field: 'collectionDate' },
            { header: 'Shop', field: 'shopName' },
            { header: 'Amount', field: 'amountReceived' },
            { header: 'Mode', field: 'paymentMode' }
          ],
          'daily-collection-report'
        );
        break;
      case 2:
        this.exportService.exportToExcel(
          this.dailyExpense(),
          [
            { header: 'Date', field: 'expenseDate' },
            { header: 'Category', field: 'categoryName' },
            { header: 'Paid To', field: 'paidTo' },
            { header: 'Amount', field: 'amount' },
            { header: 'Mode', field: 'paymentMode' }
          ],
          'daily-expense-report'
        );
        break;
      case 3:
        this.exportService.exportToExcel(
          this.purchaseReport(),
          [
            { header: 'Date', field: 'purchaseDate' },
            { header: 'Invoice No', field: 'invoiceNo' },
            { header: 'Supplier', field: 'supplierName' },
            { header: 'Amount', field: 'totalAmount' }
          ],
          'purchase-report'
        );
        break;
      case 4:
        this.exportService.exportToExcel(
          this.fruitSales(),
          [
            { header: 'Fruit', field: 'fruitName' },
            { header: 'Unit', field: 'unit' },
            { header: 'Quantity', field: 'totalQuantity' },
            { header: 'Amount', field: 'totalAmount' }
          ],
          'fruit-sales-report'
        );
        break;
      case 5:
        this.exportService.exportToExcel(
          this.outstanding(),
          [
            { header: 'Type', field: 'type' },
            { header: 'Name', field: 'name' },
            { header: 'Outstanding', field: 'outstandingAmount' }
          ],
          'outstanding-report'
        );
        break;
      case 6:
        this.exportService.exportToExcel(
          this.profitSummary(),
          [
            { header: 'Month', field: 'month' },
            { header: 'Sales', field: 'totalSales' },
            { header: 'Purchases', field: 'totalPurchases' },
            { header: 'Expenses', field: 'totalExpenses' },
            { header: 'Net Profit', field: 'netProfit' }
          ],
          'profit-summary-report'
        );
        break;
    }
  }
}
