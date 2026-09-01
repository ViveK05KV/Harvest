using FruitWholesale.Application.Common.Interfaces;
using FruitWholesale.Application.DTOs.Dashboard;
using FruitWholesale.Domain.Common;

namespace FruitWholesale.Application.Services;

public interface IDashboardService
{
    Task<DashboardSummaryDto> GetSummaryAsync(bool includeProfit);
    Task<DashboardChartsDto> GetChartsAsync();
    Task<List<TrendPointDto>> GetSalesTrendAsync(string period);
    Task<SalesVsPurchasesDto> GetSalesVsPurchasesAsync(string period);
    Task<List<TrendPointDto>> GetCashTrendAsync();
    Task<List<TrendPointDto>> GetProfitTrendAsync(bool includeProfit);
}

public class DashboardService(IDashboardRepository repository, IProfitRepository profitRepository) : IDashboardService
{
    public async Task<DashboardSummaryDto> GetSummaryAsync(bool includeProfit)
    {
        var today = BusinessClock.Today;
        var summaryTask = repository.GetSummaryAsync(today);

        if (!includeProfit)
        {
            return await summaryTask;
        }

        var totalProfitTask = profitRepository.GetBusinessTotalProfitAsync();
        var todayProfitTask = profitRepository.GetShopDailyProfitAsync(null, today, today);
        await Task.WhenAll(summaryTask, totalProfitTask, todayProfitTask);

        var summary = await summaryTask;

        // Both gross (revenue - cost of goods sold): TotalProfit since tracking
        // began, TodayProfit for today only.
        summary.TotalProfit = (await totalProfitTask).Profit;
        summary.TodayProfit = (await todayProfitTask).FirstOrDefault()?.Profit ?? 0m;
        return summary;
    }

    public async Task<DashboardChartsDto> GetChartsAsync()
    {
        var toDate = BusinessClock.Today;
        var fromDate = toDate.AddMonths(-6);

        var salesByMonthTask = repository.GetSalesByMonthAsync(6);
        var collectionsByMonthTask = repository.GetCollectionsByMonthAsync(6);
        var expensesByCategoryTask = repository.GetExpensesByCategoryAsync(fromDate, toDate);
        var totalSalaryTask = repository.GetTotalSalaryAsync(fromDate, toDate);
        var topSellingFruitsTask = repository.GetTopSellingFruitsAsync(10, fromDate, toDate);
        var topCustomersTask = repository.GetTopCustomersAsync(10, fromDate, toDate);

        await Task.WhenAll(salesByMonthTask, collectionsByMonthTask, expensesByCategoryTask, totalSalaryTask, topSellingFruitsTask, topCustomersTask);

        // "Where the money went" folds salary paid in as its own category
        // alongside the DailyExpense categories, so the breakdown reflects all
        // cash spent, not just what was logged as an expense.
        var expensesByCategory = await expensesByCategoryTask;
        var totalSalary = await totalSalaryTask;
        if (totalSalary > 0)
        {
            expensesByCategory = expensesByCategory
                .Append(new CategoryAmountDto { Category = "Salary Paid", Amount = totalSalary })
                .OrderByDescending(c => c.Amount)
                .ToList();
        }

        return new DashboardChartsDto
        {
            SalesByMonth = await salesByMonthTask,
            CollectionsByMonth = await collectionsByMonthTask,
            ExpensesByCategory = expensesByCategory,
            TopSellingFruits = await topSellingFruitsTask,
            TopCustomers = await topCustomersTask
        };
    }

    public Task<List<TrendPointDto>> GetSalesTrendAsync(string period) => repository.GetSalesTrendAsync(period);

    public async Task<SalesVsPurchasesDto> GetSalesVsPurchasesAsync(string period)
    {
        var salesTask = repository.GetSalesTrendAsync(period);
        var purchasesTask = repository.GetPurchasesTrendAsync(period);
        await Task.WhenAll(salesTask, purchasesTask);

        return new SalesVsPurchasesDto { Sales = await salesTask, Purchases = await purchasesTask };
    }

    public Task<List<TrendPointDto>> GetCashTrendAsync() => repository.GetCashTrendAsync();

    /// <summary>Last 7 calendar days of aggregate profit, zero-filled for days with no activity.
    /// Returns an empty list for non-admin/accountant callers so profit figures never reach them.</summary>
    public async Task<List<TrendPointDto>> GetProfitTrendAsync(bool includeProfit)
    {
        if (!includeProfit)
        {
            return [];
        }

        var today = BusinessClock.Today;
        var fromDate = today.AddDays(-6);
        var rows = await profitRepository.GetShopDailyProfitAsync(null, fromDate, today);
        var byDate = rows.ToDictionary(r => r.Date.Date, r => r.Profit);

        return Enumerable.Range(0, 7)
            .Select(i => fromDate.AddDays(i))
            .Select(d => new TrendPointDto { Label = d.ToString("ddd"), Amount = byDate.GetValueOrDefault(d) })
            .ToList();
    }
}
