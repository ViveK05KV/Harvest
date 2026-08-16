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
            "SELECT * FROM sp_get_dashboard_summary(@Today::date)", new { Today = today.Date });
        return result;
    }

    public async Task<List<MonthlyAmountDto>> GetSalesByMonthAsync(int months)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            SELECT TO_CHAR(SupplyDate, 'YYYY-MM') AS Month, SUM(TotalAmount) AS Amount
            FROM Supply
            WHERE SupplyDate >= (DATE_TRUNC('month', CURRENT_DATE) - MAKE_INTERVAL(months => @Months))
            GROUP BY TO_CHAR(SupplyDate, 'YYYY-MM')
            ORDER BY Month;
            """;
        var result = await connection.QueryAsync<MonthlyAmountDto>(sql, new { Months = months });
        return result.ToList();
    }

    public async Task<List<MonthlyAmountDto>> GetCollectionsByMonthAsync(int months)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            SELECT TO_CHAR(CollectionDate, 'YYYY-MM') AS Month, SUM(AmountReceived) AS Amount
            FROM Collections
            WHERE CollectionDate >= (DATE_TRUNC('month', CURRENT_DATE) - MAKE_INTERVAL(months => @Months))
            GROUP BY TO_CHAR(CollectionDate, 'YYYY-MM')
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
            FROM DailyExpense e
            INNER JOIN ExpenseCategory c ON c.ExpenseCategoryID = e.ExpenseCategoryID
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
            SELECT f.FruitName, SUM(si.Quantity) AS TotalQuantity, SUM(si.TotalAmount) AS TotalAmount
            FROM SupplyItems si
            INNER JOIN FruitMaster f ON f.FruitID = si.FruitID
            INNER JOIN Supply s ON s.SupplyID = si.SupplyID
            WHERE s.SupplyDate BETWEEN @FromDate AND @ToDate
            GROUP BY f.FruitName
            ORDER BY TotalAmount DESC
            LIMIT @Top;
            """;
        var result = await connection.QueryAsync<TopFruitDto>(sql, new { Top = top, FromDate = fromDate, ToDate = toDate });
        return result.ToList();
    }

    public async Task<List<TopCustomerDto>> GetTopCustomersAsync(int top, DateTime fromDate, DateTime toDate)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            SELECT sh.ShopName, SUM(s.TotalAmount) AS TotalAmount
            FROM Supply s
            INNER JOIN ShopMaster sh ON sh.ShopID = s.ShopID
            WHERE s.SupplyDate BETWEEN @FromDate AND @ToDate
            GROUP BY sh.ShopName
            ORDER BY TotalAmount DESC
            LIMIT @Top;
            """;
        var result = await connection.QueryAsync<TopCustomerDto>(sql, new { Top = top, FromDate = fromDate, ToDate = toDate });
        return result.ToList();
    }

    public Task<List<TrendPointDto>> GetSalesTrendAsync(string period) =>
        GetTrendAsync("Supply", "SupplyDate", "TotalAmount", period);

    public Task<List<TrendPointDto>> GetPurchasesTrendAsync(string period) =>
        GetTrendAsync("Purchase", "PurchaseDate", "TotalAmount", period);

    public Task<List<TrendPointDto>> GetCashTrendAsync() =>
        GetTrendAsync("CashLedger", "TransactionDate", "(CashIn - CashOut)", DashboardPeriods.ThisWeek);

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
        var bucketFormat = byMonth ? "YYYY-MM" : "YYYY-MM-DD";

        using var connection = connectionFactory.CreateConnection();
        var sql = $"""
            SELECT TO_CHAR({dateColumn}, '{bucketFormat}') AS BucketKey, SUM({amountColumn}) AS Amount
            FROM {table}
            WHERE {dateColumn} >= @FromDate AND {dateColumn} <= @ToDate
            GROUP BY TO_CHAR({dateColumn}, '{bucketFormat}');
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
