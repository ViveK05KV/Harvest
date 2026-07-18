using System.Data;
using Dapper;
using FruitWholesale.Application.Common.Interfaces;
using FruitWholesale.Application.DTOs.Dashboard;

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
}
