using FruitWholesale.Application.Common.Interfaces;
using FruitWholesale.Application.DTOs.Dashboard;

namespace FruitWholesale.Application.Services;

public interface IDashboardService
{
    Task<DashboardSummaryDto> GetSummaryAsync(bool includeProfit);
    Task<DashboardChartsDto> GetChartsAsync();
}

public class DashboardService(IDashboardRepository repository, IProfitRepository profitRepository) : IDashboardService
{
    public async Task<DashboardSummaryDto> GetSummaryAsync(bool includeProfit)
    {
        var today = DateTime.UtcNow.Date;
        var summaryTask = repository.GetSummaryAsync(today);

        if (!includeProfit)
        {
            return await summaryTask;
        }

        var totalProfitTask = profitRepository.GetBusinessTotalProfitAsync();
        var todayProfitTask = profitRepository.GetShopDailyProfitAsync(null, today, today);
        await Task.WhenAll(summaryTask, totalProfitTask, todayProfitTask);

        var summary = await summaryTask;
        summary.TotalProfit = (await totalProfitTask).Profit;
        summary.TodayProfit = (await todayProfitTask).FirstOrDefault()?.Profit ?? 0m;
        return summary;
    }

    public async Task<DashboardChartsDto> GetChartsAsync()
    {
        var toDate = DateTime.UtcNow.Date;
        var fromDate = toDate.AddMonths(-6);

        var salesByMonthTask = repository.GetSalesByMonthAsync(6);
        var collectionsByMonthTask = repository.GetCollectionsByMonthAsync(6);
        var expensesByCategoryTask = repository.GetExpensesByCategoryAsync(fromDate, toDate);
        var topSellingFruitsTask = repository.GetTopSellingFruitsAsync(10, fromDate, toDate);
        var topCustomersTask = repository.GetTopCustomersAsync(10, fromDate, toDate);

        await Task.WhenAll(salesByMonthTask, collectionsByMonthTask, expensesByCategoryTask, topSellingFruitsTask, topCustomersTask);

        return new DashboardChartsDto
        {
            SalesByMonth = await salesByMonthTask,
            CollectionsByMonth = await collectionsByMonthTask,
            ExpensesByCategory = await expensesByCategoryTask,
            TopSellingFruits = await topSellingFruitsTask,
            TopCustomers = await topCustomersTask
        };
    }
}
