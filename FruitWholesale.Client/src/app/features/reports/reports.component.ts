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
import { MatAutocompleteModule, MatAutocompleteSelectedEvent } from '@angular/material/autocomplete';
import { ReportService } from './report.service';
import { ExportService } from '../../core/services/export.service';
import { EmployeeService } from '../employee/employee.service';
import { firstOfMonth, toIso } from '../../core/utils/date.util';
import { Employee } from '../../core/models/master-data.model';
import {
  DailyCollectionReportRow,
  DailyExpenseReportRow,
  DailySalesReportRow,
  ExpenseByCategoryReportRow,
  FruitSalesReportRow,
  OutstandingReportRow,
  ProfitSummaryReportRow,
  PurchaseReportRow,
  SalaryByEmployeeReportRow
} from '../../core/models/report.model';

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
    MatProgressBarModule,
    MatAutocompleteModule
  ],
  templateUrl: './reports.component.html'
})
export class ReportsComponent implements OnInit {
  private readonly reportService = inject(ReportService);
  private readonly exportService = inject(ExportService);
  private readonly employeeService = inject(EmployeeService);

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
  readonly expenseByCategory = signal<ExpenseByCategoryReportRow[]>([]);
  readonly salaryByEmployee = signal<SalaryByEmployeeReportRow[]>([]);

  readonly dailySalesColumns = ['supplyDate', 'invoiceNo', 'shopName', 'totalAmount'];
  readonly dailyCollectionColumns = ['collectionDate', 'shopName', 'amountReceived', 'paymentMode'];
  readonly dailyExpenseColumns = ['expenseDate', 'categoryName', 'paidTo', 'amount', 'paymentMode'];
  readonly purchaseColumns = ['purchaseDate', 'invoiceNo', 'supplierName', 'totalAmount'];
  readonly fruitSalesColumns = ['fruitName', 'unit', 'totalQuantity', 'totalAmount'];
  readonly outstandingColumns = ['type', 'name', 'outstandingAmount'];
  readonly profitColumns = ['month', 'totalSales', 'totalPurchases', 'totalExpenses', 'netProfit'];
  readonly expenseByCategoryColumns = ['categoryName', 'totalAmount'];
  readonly salaryByEmployeeColumns = ['employeeName', 'workDaysCount', 'totalAmount'];
  private loadRequestId = 0;

  // Salary tab's employee filter - same searchable-dropdown pattern as the
  // shop/supplier filters used across the transaction list pages.
  readonly employees = signal<Employee[]>([]);
  employeeId: number | null = null;
  employeeSearch = '';

  ngOnInit(): void {
    this.employeeService.getAllActive().subscribe((employees) => this.employees.set(employees));
    this.loadActiveTab();
  }

  filteredEmployees(search: string | null | undefined): Employee[] {
    const term = (search ?? '').trim().toLowerCase();
    if (!term) return this.employees();
    return this.employees().filter((e) => e.fullName.toLowerCase().includes(term));
  }

  readonly displayEmployee = (value: unknown): string =>
    typeof value === 'number' ? (this.employees().find((e) => e.employeeID === value)?.fullName ?? '') : typeof value === 'string' ? value : '';

  onEmployeeFilterSelected(event: MatAutocompleteSelectedEvent): void {
    const employeeId = event.option.value as number | null;
    this.employeeId = employeeId;
    this.employeeSearch = employeeId == null ? '' : (this.employees().find((e) => e.employeeID === employeeId)?.fullName ?? '');
    this.onFilterChange();
  }

  onEmployeeSearchFocus(): void {
    if (this.employeeSearch === (this.employees().find((e) => e.employeeID === this.employeeId)?.fullName ?? '')) this.employeeSearch = '';
  }

  // Typing away from the selected employee must clear the stale filter and
  // reload - otherwise the field shows different text while the table stays
  // silently filtered by whatever employee was previously selected.
  onEmployeeSearchInput(): void {
    this.employeeId = null;
    this.onFilterChange();
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

    // A stale response from a previous tab/filter must not overwrite a newer
    // one's data or flip loading false while a newer request is still pending.
    const requestId = ++this.loadRequestId;
    const isStale = () => requestId !== this.loadRequestId;
    const finish = () => {
      if (!isStale()) this.loading.set(false);
    };

    switch (this.activeTab()) {
      case 0:
        this.reportService.getDailySales(from, to).subscribe({
          next: (r) => {
            if (isStale()) return;
            this.dailySales.set(r);
            finish();
          },
          error: finish
        });
        break;
      case 1:
        this.reportService.getDailyCollection(from, to).subscribe({
          next: (r) => {
            if (isStale()) return;
            this.dailyCollection.set(r);
            finish();
          },
          error: finish
        });
        break;
      case 2:
        this.reportService.getDailyExpense(from, to).subscribe({
          next: (r) => {
            if (isStale()) return;
            this.dailyExpense.set(r);
            finish();
          },
          error: finish
        });
        break;
      case 3:
        this.reportService.getPurchaseReport(from, to).subscribe({
          next: (r) => {
            if (isStale()) return;
            this.purchaseReport.set(r);
            finish();
          },
          error: finish
        });
        break;
      case 4:
        this.reportService.getFruitSales(from, to).subscribe({
          next: (r) => {
            if (isStale()) return;
            this.fruitSales.set(r);
            finish();
          },
          error: finish
        });
        break;
      case 5:
        this.reportService.getOutstanding().subscribe({
          next: (r) => {
            if (isStale()) return;
            this.outstanding.set(r);
            finish();
          },
          error: finish
        });
        break;
      case 6:
        this.reportService.getProfitSummary(from, to).subscribe({
          next: (r) => {
            if (isStale()) return;
            this.profitSummary.set(r);
            finish();
          },
          error: finish
        });
        break;
      case 7:
        this.reportService.getExpenseByCategory(from, to).subscribe({
          next: (r) => {
            if (isStale()) return;
            this.expenseByCategory.set(r);
            finish();
          },
          error: finish
        });
        break;
      case 8:
        this.reportService.getSalaryByEmployee(from, to, this.employeeId).subscribe({
          next: (r) => {
            if (isStale()) return;
            this.salaryByEmployee.set(r);
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
      case 7:
        this.exportService.exportToExcel(
          this.expenseByCategory(),
          [
            { header: 'Category', field: 'categoryName' },
            { header: 'Amount', field: 'totalAmount' }
          ],
          'expense-by-category-report'
        );
        break;
      case 8:
        this.exportService.exportToExcel(
          this.salaryByEmployee(),
          [
            { header: 'Employee', field: 'employeeName' },
            { header: 'Work Days', field: 'workDaysCount' },
            { header: 'Amount', field: 'totalAmount' }
          ],
          'salary-by-employee-report'
        );
        break;
    }
  }
}
