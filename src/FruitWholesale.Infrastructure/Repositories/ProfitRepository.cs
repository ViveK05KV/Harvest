using Dapper;
using FruitWholesale.Application.Common.Interfaces;
using FruitWholesale.Application.DTOs.Profit;
using FruitWholesale.Domain.Enums;

namespace FruitWholesale.Infrastructure.Repositories;

public class ProfitRepository(IDbConnectionFactory connectionFactory) : IProfitRepository
{
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
            SELECT COALESCE(SUM(si.TotalAmount), 0) AS Revenue,
                   COALESCE(SUM(si.Quantity * si.CostBasis), 0) AS Cost,
                   COALESCE(SUM(si.TotalAmount - si.Quantity * si.CostBasis), 0) AS Profit
            FROM SupplyItems si
            INNER JOIN Supply s ON s.SupplyID = si.SupplyID
            WHERE s.SupplyDate >= @FromDate;
            """;
        var total = await connection.QuerySingleAsync<BusinessProfitTotal>(sql, new { FromDate = ProfitConstants.TrackingStartDate });
        total.MarginPercent = ComputeMargin(total.Revenue, total.Profit);
        return total;
    }

    private static decimal ComputeMargin(decimal revenue, decimal profit) =>
        revenue == 0 ? 0 : Math.Round(profit / revenue * 100, 2);
}
