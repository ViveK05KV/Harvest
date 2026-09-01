using FruitWholesale.Application.DTOs.Dashboard;
using FruitWholesale.Application.DTOs.Profit;
using FruitWholesale.Application.DTOs.Reports;

namespace FruitWholesale.Application.Common.Interfaces;

public interface IDashboardRepository
{
    Task<DashboardSummaryDto> GetSummaryAsync(DateTime today);
    Task<List<MonthlyAmountDto>> GetSalesByMonthAsync(int months);
    Task<List<MonthlyAmountDto>> GetCollectionsByMonthAsync(int months);
    Task<List<CategoryAmountDto>> GetExpensesByCategoryAsync(DateTime fromDate, DateTime toDate);
    Task<decimal> GetTotalSalaryAsync(DateTime fromDate, DateTime toDate);
    Task<List<TopFruitDto>> GetTopSellingFruitsAsync(int top, DateTime fromDate, DateTime toDate);
    Task<List<TopCustomerDto>> GetTopCustomersAsync(int top, DateTime fromDate, DateTime toDate);
    Task<List<TrendPointDto>> GetSalesTrendAsync(string period);
    Task<List<TrendPointDto>> GetPurchasesTrendAsync(string period);
    Task<List<TrendPointDto>> GetCashTrendAsync();
}

public interface IReportRepository
{
    Task<List<DailySalesReportRow>> GetDailySalesAsync(DateTime fromDate, DateTime toDate, int? shopId);
    Task<List<DailyCollectionReportRow>> GetDailyCollectionAsync(DateTime fromDate, DateTime toDate, int? shopId);
    Task<List<DailyExpenseReportRow>> GetDailyExpenseAsync(DateTime fromDate, DateTime toDate, int? expenseCategoryId);
    Task<List<DailyExpenseReportRow>> GetDailySalaryAsync(DateTime fromDate, DateTime toDate);
    Task<List<PurchaseReportRow>> GetPurchaseReportAsync(DateTime fromDate, DateTime toDate, int? supplierId);
    Task<List<FruitSalesReportRow>> GetFruitSalesReportAsync(DateTime fromDate, DateTime toDate);
    Task<List<OutstandingReportRow>> GetOutstandingReportAsync();
    Task<List<ProfitSummaryReportRow>> GetProfitSummaryAsync(DateTime fromDate, DateTime toDate);
    Task<List<ExpenseByCategoryReportRow>> GetExpenseByCategoryAsync(DateTime fromDate, DateTime toDate);
    Task<List<SalaryByEmployeeReportRow>> GetSalaryByEmployeeAsync(DateTime fromDate, DateTime toDate, int? employeeId);
}

public interface IProfitRepository
{
    Task<List<ShopDailyProfitRow>> GetShopDailyProfitAsync(int? shopId, DateTime? fromDate, DateTime? toDate);
    Task<List<ShopProfitSummaryRow>> GetShopProfitSummaryAsync(DateTime? fromDate, DateTime? toDate);
    Task<List<FruitProfitSummaryRow>> GetFruitProfitSummaryAsync(DateTime? fromDate, DateTime? toDate);
    Task<List<ShopFruitProfitRow>> GetShopFruitProfitAsync(int? shopId, DateTime? fromDate, DateTime? toDate);
    Task<BusinessProfitTotal> GetBusinessTotalProfitAsync();
}
