using FruitWholesale.Application.Common.Interfaces;
using FruitWholesale.Application.DTOs.Reports;

namespace FruitWholesale.Application.Services;

public interface IReportService
{
    Task<List<DailySalesReportRow>> GetDailySalesAsync(DateTime fromDate, DateTime toDate, int? shopId);
    Task<List<DailyCollectionReportRow>> GetDailyCollectionAsync(DateTime fromDate, DateTime toDate, int? shopId);
    Task<List<DailyExpenseReportRow>> GetDailyExpenseAsync(DateTime fromDate, DateTime toDate, int? expenseCategoryId);
    Task<List<PurchaseReportRow>> GetPurchaseReportAsync(DateTime fromDate, DateTime toDate, int? supplierId);
    Task<List<FruitSalesReportRow>> GetFruitSalesReportAsync(DateTime fromDate, DateTime toDate);
    Task<List<OutstandingReportRow>> GetOutstandingReportAsync();
    Task<List<ProfitSummaryReportRow>> GetProfitSummaryAsync(DateTime fromDate, DateTime toDate);
    Task<List<ExpenseByCategoryReportRow>> GetExpenseByCategoryAsync(DateTime fromDate, DateTime toDate);
    Task<List<SalaryByEmployeeReportRow>> GetSalaryByEmployeeAsync(DateTime fromDate, DateTime toDate, int? employeeId);
}

public class ReportService(IReportRepository repository) : IReportService
{
    public Task<List<DailySalesReportRow>> GetDailySalesAsync(DateTime fromDate, DateTime toDate, int? shopId) =>
        repository.GetDailySalesAsync(fromDate, toDate, shopId);

    public Task<List<DailyCollectionReportRow>> GetDailyCollectionAsync(DateTime fromDate, DateTime toDate, int? shopId) =>
        repository.GetDailyCollectionAsync(fromDate, toDate, shopId);

    public Task<List<DailyExpenseReportRow>> GetDailyExpenseAsync(DateTime fromDate, DateTime toDate, int? expenseCategoryId) =>
        repository.GetDailyExpenseAsync(fromDate, toDate, expenseCategoryId);

    public Task<List<PurchaseReportRow>> GetPurchaseReportAsync(DateTime fromDate, DateTime toDate, int? supplierId) =>
        repository.GetPurchaseReportAsync(fromDate, toDate, supplierId);

    public Task<List<FruitSalesReportRow>> GetFruitSalesReportAsync(DateTime fromDate, DateTime toDate) =>
        repository.GetFruitSalesReportAsync(fromDate, toDate);

    public Task<List<OutstandingReportRow>> GetOutstandingReportAsync() => repository.GetOutstandingReportAsync();

    public Task<List<ProfitSummaryReportRow>> GetProfitSummaryAsync(DateTime fromDate, DateTime toDate) =>
        repository.GetProfitSummaryAsync(fromDate, toDate);

    public Task<List<ExpenseByCategoryReportRow>> GetExpenseByCategoryAsync(DateTime fromDate, DateTime toDate) =>
        repository.GetExpenseByCategoryAsync(fromDate, toDate);

    public Task<List<SalaryByEmployeeReportRow>> GetSalaryByEmployeeAsync(DateTime fromDate, DateTime toDate, int? employeeId) =>
        repository.GetSalaryByEmployeeAsync(fromDate, toDate, employeeId);
}
