using FruitWholesale.Application.DTOs.Dashboard;
using FruitWholesale.Application.DTOs.Reports;

namespace FruitWholesale.Application.Common.Interfaces;

public interface IDashboardRepository
{
    Task<DashboardSummaryDto> GetSummaryAsync(DateTime today);
    Task<List<MonthlyAmountDto>> GetSalesByMonthAsync(int months);
    Task<List<MonthlyAmountDto>> GetCollectionsByMonthAsync(int months);
    Task<List<CategoryAmountDto>> GetExpensesByCategoryAsync(DateTime fromDate, DateTime toDate);
    Task<List<TopFruitDto>> GetTopSellingFruitsAsync(int top, DateTime fromDate, DateTime toDate);
    Task<List<TopCustomerDto>> GetTopCustomersAsync(int top, DateTime fromDate, DateTime toDate);
}

public interface IReportRepository
{
    Task<List<DailySalesReportRow>> GetDailySalesAsync(DateTime fromDate, DateTime toDate, int? shopId);
    Task<List<DailyCollectionReportRow>> GetDailyCollectionAsync(DateTime fromDate, DateTime toDate, int? shopId);
    Task<List<DailyExpenseReportRow>> GetDailyExpenseAsync(DateTime fromDate, DateTime toDate, int? expenseCategoryId);
    Task<List<PurchaseReportRow>> GetPurchaseReportAsync(DateTime fromDate, DateTime toDate, int? supplierId);
    Task<List<FruitSalesReportRow>> GetFruitSalesReportAsync(DateTime fromDate, DateTime toDate);
    Task<List<OutstandingReportRow>> GetOutstandingReportAsync();
    Task<List<ProfitSummaryReportRow>> GetProfitSummaryAsync(DateTime fromDate, DateTime toDate);
}
