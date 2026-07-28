using System.Data;
using Dapper;
using FruitWholesale.Application.Common.Interfaces;
using FruitWholesale.Application.DTOs.Dashboard;
using FruitWholesale.Domain.Enums;

namespace FruitWholesale.Infrastructure.Repositories;

public class DashboardRepository(IDbConnectionFactory connectionFactory) : IDashboardRepository
{
    public async Task<DashboardSummaryDto> GetSummaryAsync(DateTime today)
    {
        using var connection = connectionFactory.CreateConnection();
        var result = await connection.QuerySingleAsync<DashboardSummaryDto>(
            "dbo.sp_GetDashboardSummary", new { Today = today.Date }, commandType: CommandType.StoredProcedure);
        return result;
    }

    public async Task<List<MonthlyAmountDto>> GetSalesByMonthAsync(int months)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            SELECT FORMAT(SupplyDate, 'yyyy-MM') AS Month, SUM(TotalAmount) AS Amount
            FROM dbo.Supply
            WHERE SupplyDate >= DATEADD(MONTH, -@Months, DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1))
            GROUP BY FORMAT(SupplyDate, 'yyyy-MM')
            ORDER BY Month;
            """;
        var result = await connection.QueryAsync<MonthlyAmountDto>(sql, new { Months = months });
        return result.ToList();
    }

    public async Task<List<MonthlyAmountDto>> GetCollectionsByMonthAsync(int months)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            SELECT FORMAT(CollectionDate, 'yyyy-MM') AS Month, SUM(AmountReceived) AS Amount
            FROM dbo.Collections
            WHERE CollectionDate >= DATEADD(MONTH, -@Months, DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1))
            GROUP BY FORMAT(CollectionDate, 'yyyy-MM')
            ORDER BY Month;
            """;
        var result = await connection.QueryAsync<MonthlyAmountDto>(sql, new { Months = months });
        return result.ToList();
    }

    public async Task<List<CategoryAmountDto>> GetExpensesByCategoryAsync(DateTime fromDate, DateTime toDate)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            SELECT c.CategoryName AS Category, SUM(e.Amount) AS Amount
            FROM dbo.DailyExpense e
            INNER JOIN dbo.ExpenseCategory c ON c.ExpenseCategoryID = e.ExpenseCategoryID
            WHERE e.ExpenseDate BETWEEN @FromDate AND @ToDate
            GROUP BY c.CategoryName
            ORDER BY Amount DESC;
            """;
        var result = await connection.QueryAsync<CategoryAmountDto>(sql, new { FromDate = fromDate, ToDate = toDate });
        return result.ToList();
    }

    public async Task<List<TopFruitDto>> GetTopSellingFruitsAsync(int top, DateTime fromDate, DateTime toDate)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            SELECT TOP (@Top) f.FruitName, SUM(si.Quantity) AS TotalQuantity, SUM(si.TotalAmount) AS TotalAmount
            FROM dbo.SupplyItems si
            INNER JOIN dbo.FruitMaster f ON f.FruitID = si.FruitID
            INNER JOIN dbo.Supply s ON s.SupplyID = si.SupplyID
            WHERE s.SupplyDate BETWEEN @FromDate AND @ToDate
            GROUP BY f.FruitName
            ORDER BY TotalAmount DESC;
            """;
        var result = await connection.QueryAsync<TopFruitDto>(sql, new { Top = top, FromDate = fromDate, ToDate = toDate });
        return result.ToList();
    }

    public async Task<List<TopCustomerDto>> GetTopCustomersAsync(int top, DateTime fromDate, DateTime toDate)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            SELECT TOP (@Top) sh.ShopName, SUM(s.TotalAmount) AS TotalAmount
            FROM dbo.Supply s
            INNER JOIN dbo.ShopMaster sh ON sh.ShopID = s.ShopID
            WHERE s.SupplyDate BETWEEN @FromDate AND @ToDate
            GROUP BY sh.ShopName
            ORDER BY TotalAmount DESC;
            """;
        var result = await connection.QueryAsync<TopCustomerDto>(sql, new { Top = top, FromDate = fromDate, ToDate = toDate });
        return result.ToList();
    }

    public Task<List<TrendPointDto>> GetSalesTrendAsync(string period) =>
        GetTrendAsync("Supply", "SupplyDate", "TotalAmount", period);

    public Task<List<TrendPointDto>> GetPurchasesTrendAsync(string period) =>
        GetTrendAsync("Purchase", "PurchaseDate", "TotalAmount", period);

    /// <summary>
    /// Builds a fixed set of buckets ("the spine") for the requested period first,
    /// then fills in real amounts from whichever rows exist — so a day/month with
    /// no activity still shows as a zero point instead of being skipped, keeping
    /// the x-axis evenly spaced no matter how sparse the data is.
    /// table/dateColumn/amountColumn are always call-site literals (never user
    /// input), so interpolating them into the SQL text here is safe.
    /// </summary>
    private async Task<List<TrendPointDto>> GetTrendAsync(string table, string dateColumn, string amountColumn, string period)
    {
        var (spine, byMonth) = BuildSpine(period);
        var fromDate = spine[0].Date;
        var toDate = byMonth ? spine[^1].Date.AddMonths(1).AddDays(-1) : spine[^1].Date;
        var bucketFormat = byMonth ? "yyyy-MM" : "yyyy-MM-dd";

        using var connection = connectionFactory.CreateConnection();
        var sql = $"""
            SELECT FORMAT({dateColumn}, '{bucketFormat}') AS BucketKey, SUM({amountColumn}) AS Amount
            FROM dbo.{table}
            WHERE {dateColumn} >= @FromDate AND {dateColumn} <= @ToDate
            GROUP BY FORMAT({dateColumn}, '{bucketFormat}');
            """;
        var rows = await connection.QueryAsync<(string BucketKey, decimal Amount)>(sql, new { FromDate = fromDate, ToDate = toDate });
        var byKey = rows.ToDictionary(r => r.BucketKey, r => r.Amount);

        return spine
            .Select(s => new TrendPointDto
            {
                Label = s.Label,
                Amount = byKey.TryGetValue(s.Date.ToString(byMonth ? "yyyy-MM" : "yyyy-MM-dd"), out var amount) ? amount : 0m
            })
            .ToList();
    }

    private static (List<(DateTime Date, string Label)> Points, bool ByMonth) BuildSpine(string period)
    {
        var today = DateTime.UtcNow.Date;
        switch (period)
        {
            case DashboardPeriods.ThisWeek:
            {
                var daysSinceMonday = ((int)today.DayOfWeek + 6) % 7;
                var monday = today.AddDays(-daysSinceMonday);
                var points = Enumerable.Range(0, 7).Select(i => (monday.AddDays(i), monday.AddDays(i).ToString("ddd"))).ToList();
                return (points, false);
            }
            case DashboardPeriods.ThisMonth:
            {
                var first = new DateTime(today.Year, today.Month, 1);
                var daysInMonth = DateTime.DaysInMonth(today.Year, today.Month);
                var points = Enumerable.Range(0, daysInMonth).Select(i => (first.AddDays(i), first.AddDays(i).Day.ToString())).ToList();
                return (points, false);
            }
            case DashboardPeriods.Last6Months:
            {
                var firstMonth = new DateTime(today.Year, today.Month, 1).AddMonths(-5);
                var points = Enumerable.Range(0, 6).Select(i => (firstMonth.AddMonths(i), firstMonth.AddMonths(i).ToString("MMM"))).ToList();
                return (points, true);
            }
            case DashboardPeriods.Last12Months:
            default:
            {
                var firstMonth = new DateTime(today.Year, today.Month, 1).AddMonths(-11);
                var points = Enumerable.Range(0, 12).Select(i => (firstMonth.AddMonths(i), firstMonth.AddMonths(i).ToString("MMM"))).ToList();
                return (points, true);
            }
        }
    }
}
