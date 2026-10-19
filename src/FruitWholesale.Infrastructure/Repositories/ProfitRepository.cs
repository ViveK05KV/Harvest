using Dapper;
using FruitWholesale.Application.Common.Interfaces;
using FruitWholesale.Application.DTOs.Profit;
using FruitWholesale.Domain.Enums;

namespace FruitWholesale.Infrastructure.Repositories;

public class ProfitRepository(IDbConnectionFactory connectionFactory) : IProfitRepository
{
    public async Task<List<ActualProfitRow>> GetActualProfitAsync(int? shopId, DateTime? fromDate, DateTime? toDate)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            WITH date_range AS (
                SELECT GREATEST(COALESCE(@FromDate::date, @TrackingStartDate::date), @TrackingStartDate::date) AS from_date,
                       COALESCE(@ToDate::date, CURRENT_DATE) AS to_date
            ), days AS (
                SELECT generate_series(from_date, to_date, INTERVAL '1 day')::date AS date
                FROM date_range WHERE from_date <= to_date
            ), sales AS (
                SELECT s.SupplyDate AS date,
                       CASE WHEN @ShopID::int IS NULL THEN NULL ELSE MAX(sh.ShopName) END AS customer_name,
                       SUM(si.TotalAmount) AS revenue,
                       SUM(si.Quantity * si.CostBasis) AS purchase_cost
                FROM SupplyItems si
                INNER JOIN Supply s ON s.SupplyID = si.SupplyID
                INNER JOIN ShopMaster sh ON sh.ShopID = s.ShopID
                CROSS JOIN date_range r
                WHERE s.SupplyDate BETWEEN r.from_date AND r.to_date
                  AND (@ShopID::int IS NULL OR s.ShopID = @ShopID)
                GROUP BY s.SupplyDate
            )
            SELECT d.date AS Date, s.customer_name AS CustomerName,
                   COALESCE(s.revenue, 0) AS Sales,
                   COALESCE(s.purchase_cost, 0) AS PurchaseCost,
                   COALESCE(s.revenue, 0) - COALESCE(s.purchase_cost, 0) AS ActualProfit
            FROM days d
            LEFT JOIN sales s ON s.date = d.date
            ORDER BY d.date;
            """;
        return (await connection.QueryAsync<ActualProfitRow>(sql, new
        {
            ShopID = shopId,
            FromDate = fromDate,
            ToDate = toDate,
            TrackingStartDate = ProfitConstants.TrackingStartDate
        })).ToList();
    }

    public async Task<List<BusinessDailyProfitRow>> GetBusinessDailyProfitAsync(DateTime? fromDate, DateTime? toDate)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            WITH date_range AS (
                SELECT GREATEST(COALESCE(@FromDate::date, @TrackingStartDate::date), @TrackingStartDate::date) AS from_date,
                       COALESCE(@ToDate::date, CURRENT_DATE) AS to_date
            ), days AS (
                SELECT generate_series(from_date, to_date, INTERVAL '1 day')::date AS date
                FROM date_range
                WHERE from_date <= to_date
            ), sales AS (
                SELECT s.SupplyDate AS date,
                       SUM(si.TotalAmount) AS revenue,
                       SUM(si.Quantity * si.CostBasis) AS cost,
                       SUM(si.TotalAmount - si.Quantity * si.CostBasis) AS profit
                FROM SupplyItems si
                INNER JOIN Supply s ON s.SupplyID = si.SupplyID
                CROSS JOIN date_range r
                WHERE s.SupplyDate BETWEEN r.from_date AND r.to_date
                GROUP BY s.SupplyDate
            ), expenses AS (
                SELECT de.ExpenseDate AS date, SUM(de.Amount) AS total
                FROM DailyExpense de
                CROSS JOIN date_range r
                WHERE de.ExpenseDate BETWEEN r.from_date AND r.to_date
                GROUP BY de.ExpenseDate
            )
            SELECT d.date AS Date,
                   COALESCE(s.revenue, 0) AS Revenue,
                   COALESCE(s.cost, 0) AS Cost,
                   COALESCE(s.profit, 0) AS Profit,
                   COALESCE(e.total, 0) AS Expenses,
                   COALESCE(s.profit, 0) - COALESCE(e.total, 0) AS NetProfit
            FROM days d
            LEFT JOIN sales s ON s.date = d.date
            LEFT JOIN expenses e ON e.date = d.date
            ORDER BY d.date;
            """;
        var rows = (await connection.QueryAsync<BusinessDailyProfitRow>(sql, new
        {
            FromDate = fromDate,
            ToDate = toDate,
            TrackingStartDate = ProfitConstants.TrackingStartDate
        })).ToList();
        foreach (var row in rows) row.MarginPercent = ComputeMargin(row.Revenue, row.Profit);
        return rows;
    }

    public async Task<List<ShopDailyProfitRow>> GetShopDailyProfitAsync(int? shopId, DateTime? fromDate, DateTime? toDate)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            SELECT s.SupplyDate AS Date,
                   SUM(si.TotalAmount) AS Revenue,
                   SUM(si.Quantity * si.CostBasis) AS Cost,
                   SUM(si.TotalAmount - si.Quantity * si.CostBasis) AS Profit
            FROM SupplyItems si
            INNER JOIN Supply s ON s.SupplyID = si.SupplyID
            WHERE (@ShopID::int IS NULL OR s.ShopID = @ShopID)
              AND (@FromDate::date IS NULL OR s.SupplyDate >= @FromDate)
              AND (@ToDate::date IS NULL OR s.SupplyDate <= @ToDate)
            GROUP BY s.SupplyDate
            ORDER BY s.SupplyDate ASC;
            """;
        var rows = (await connection.QueryAsync<ShopDailyProfitRow>(sql, new { ShopID = shopId, FromDate = fromDate, ToDate = toDate })).ToList();
        foreach (var row in rows) row.MarginPercent = ComputeMargin(row.Revenue, row.Profit);
        return rows;
    }

    public async Task<List<ShopProfitSummaryRow>> GetShopProfitSummaryAsync(DateTime? fromDate, DateTime? toDate)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            SELECT sh.ShopID, sh.ShopName,
                   SUM(si.TotalAmount) AS Revenue,
                   SUM(si.Quantity * si.CostBasis) AS Cost,
                   SUM(si.TotalAmount - si.Quantity * si.CostBasis) AS Profit
            FROM SupplyItems si
            INNER JOIN Supply s ON s.SupplyID = si.SupplyID
            INNER JOIN ShopMaster sh ON sh.ShopID = s.ShopID
            WHERE (@FromDate::date IS NULL OR s.SupplyDate >= @FromDate)
              AND (@ToDate::date IS NULL OR s.SupplyDate <= @ToDate)
            GROUP BY sh.ShopID, sh.ShopName
            ORDER BY Profit DESC;
            """;
        var rows = (await connection.QueryAsync<ShopProfitSummaryRow>(sql, new { FromDate = fromDate, ToDate = toDate })).ToList();
        foreach (var row in rows) row.MarginPercent = ComputeMargin(row.Revenue, row.Profit);
        return rows;
    }

    public async Task<List<FruitProfitSummaryRow>> GetFruitProfitSummaryAsync(DateTime? fromDate, DateTime? toDate)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            SELECT f.FruitID, f.FruitName, f.Unit,
                   SUM(si.Quantity) AS QuantitySold,
                   SUM(si.TotalAmount) AS Revenue,
                   SUM(si.Quantity * si.CostBasis) AS Cost,
                   SUM(si.TotalAmount - si.Quantity * si.CostBasis) AS Profit
            FROM SupplyItems si
            INNER JOIN Supply s ON s.SupplyID = si.SupplyID
            INNER JOIN FruitMaster f ON f.FruitID = si.FruitID
            WHERE (@FromDate::date IS NULL OR s.SupplyDate >= @FromDate)
              AND (@ToDate::date IS NULL OR s.SupplyDate <= @ToDate)
            GROUP BY f.FruitID, f.FruitName, f.Unit
            ORDER BY Profit DESC;
            """;
        var rows = (await connection.QueryAsync<FruitProfitSummaryRow>(sql, new { FromDate = fromDate, ToDate = toDate })).ToList();
        foreach (var row in rows) row.MarginPercent = ComputeMargin(row.Revenue, row.Profit);
        return rows;
    }

    public async Task<List<ShopFruitProfitRow>> GetShopFruitProfitAsync(int? shopId, DateTime? fromDate, DateTime? toDate)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            SELECT sh.ShopID, sh.ShopName, f.FruitID, f.FruitName, f.Unit,
                   SUM(si.Quantity) AS QuantitySold,
                   SUM(si.TotalAmount) AS Revenue,
                   SUM(si.Quantity * si.CostBasis) AS Cost,
                   SUM(si.TotalAmount - si.Quantity * si.CostBasis) AS Profit
            FROM SupplyItems si
            INNER JOIN Supply s ON s.SupplyID = si.SupplyID
            INNER JOIN ShopMaster sh ON sh.ShopID = s.ShopID
            INNER JOIN FruitMaster f ON f.FruitID = si.FruitID
            WHERE (@ShopID::int IS NULL OR s.ShopID = @ShopID)
              AND (@FromDate::date IS NULL OR s.SupplyDate >= @FromDate)
              AND (@ToDate::date IS NULL OR s.SupplyDate <= @ToDate)
            GROUP BY sh.ShopID, sh.ShopName, f.FruitID, f.FruitName, f.Unit
            ORDER BY sh.ShopName, Profit DESC;
            """;
        var rows = (await connection.QueryAsync<ShopFruitProfitRow>(sql, new { ShopID = shopId, FromDate = fromDate, ToDate = toDate })).ToList();
        foreach (var row in rows) row.MarginPercent = ComputeMargin(row.Revenue, row.Profit);
        return rows;
    }

    public async Task<BusinessProfitTotal> GetBusinessTotalProfitAsync()
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            SELECT COALESCE(sales.Revenue, 0) AS Revenue,
                   COALESCE(sales.Cost, 0) AS Cost,
                   COALESCE(sales.Profit, 0) AS Profit,
                   COALESCE(expenses.Total, 0) AS Expenses,
                   COALESCE(sales.Profit, 0) - COALESCE(expenses.Total, 0) AS NetProfit
            FROM (
                SELECT SUM(si.TotalAmount) AS Revenue,
                       SUM(si.Quantity * si.CostBasis) AS Cost,
                       SUM(si.TotalAmount - si.Quantity * si.CostBasis) AS Profit
                FROM SupplyItems si
                INNER JOIN Supply s ON s.SupplyID = si.SupplyID
                WHERE s.SupplyDate >= @FromDate
            ) sales
            CROSS JOIN (
                SELECT SUM(Amount) AS Total
                FROM DailyExpense
                WHERE ExpenseDate >= @FromDate
            ) expenses;
            """;
        var total = await connection.QuerySingleAsync<BusinessProfitTotal>(sql, new { FromDate = ProfitConstants.TrackingStartDate });
        total.MarginPercent = ComputeMargin(total.Revenue, total.Profit);
        return total;
    }

    private static decimal ComputeMargin(decimal revenue, decimal profit) =>
        revenue == 0 ? 0 : Math.Round(profit / revenue * 100, 2);
}
