using Dapper;
using FruitWholesale.Application.Common.Interfaces;
using FruitWholesale.Application.DTOs.Reports;

namespace FruitWholesale.Infrastructure.Repositories;

public class ReportRepository(IDbConnectionFactory connectionFactory) : IReportRepository
{
    public async Task<List<DailySalesReportRow>> GetDailySalesAsync(DateTime fromDate, DateTime toDate, int? shopId)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            SELECT s.SupplyDate, s.InvoiceNo, sh.ShopName, s.TotalAmount
            FROM dbo.Supply s
            INNER JOIN dbo.ShopMaster sh ON sh.ShopID = s.ShopID
            WHERE s.SupplyDate BETWEEN @FromDate AND @ToDate
              AND (@ShopID IS NULL OR s.ShopID = @ShopID)
            ORDER BY s.SupplyDate, s.InvoiceNo;
            """;
        var result = await connection.QueryAsync<DailySalesReportRow>(sql, new { FromDate = fromDate, ToDate = toDate, ShopID = shopId });
        return result.ToList();
    }

    public async Task<List<DailyCollectionReportRow>> GetDailyCollectionAsync(DateTime fromDate, DateTime toDate, int? shopId)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            SELECT c.CollectionDate, sh.ShopName, c.AmountReceived, c.PaymentMode
            FROM dbo.Collections c
            INNER JOIN dbo.ShopMaster sh ON sh.ShopID = c.ShopID
            WHERE c.CollectionDate BETWEEN @FromDate AND @ToDate
              AND (@ShopID IS NULL OR c.ShopID = @ShopID)
            ORDER BY c.CollectionDate;
            """;
        var result = await connection.QueryAsync<DailyCollectionReportRow>(sql, new { FromDate = fromDate, ToDate = toDate, ShopID = shopId });
        return result.ToList();
    }

    public async Task<List<DailyExpenseReportRow>> GetDailyExpenseAsync(DateTime fromDate, DateTime toDate, int? expenseCategoryId)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            SELECT e.ExpenseDate, c.CategoryName, e.Amount, ISNULL(e.PaidTo, '') AS PaidTo, e.PaymentMode
            FROM dbo.DailyExpense e
            INNER JOIN dbo.ExpenseCategory c ON c.ExpenseCategoryID = e.ExpenseCategoryID
            WHERE e.ExpenseDate BETWEEN @FromDate AND @ToDate
              AND (@ExpenseCategoryID IS NULL OR e.ExpenseCategoryID = @ExpenseCategoryID)
            ORDER BY e.ExpenseDate;
            """;
        var result = await connection.QueryAsync<DailyExpenseReportRow>(sql, new { FromDate = fromDate, ToDate = toDate, ExpenseCategoryID = expenseCategoryId });
        return result.ToList();
    }

    public async Task<List<PurchaseReportRow>> GetPurchaseReportAsync(DateTime fromDate, DateTime toDate, int? supplierId)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            SELECT p.PurchaseDate, p.InvoiceNo, s.SupplierName, p.TotalAmount
            FROM dbo.Purchase p
            INNER JOIN dbo.SupplierMaster s ON s.SupplierID = p.SupplierID
            WHERE p.PurchaseDate BETWEEN @FromDate AND @ToDate
              AND (@SupplierID IS NULL OR p.SupplierID = @SupplierID)
            ORDER BY p.PurchaseDate, p.InvoiceNo;
            """;
        var result = await connection.QueryAsync<PurchaseReportRow>(sql, new { FromDate = fromDate, ToDate = toDate, SupplierID = supplierId });
        return result.ToList();
    }

    public async Task<List<FruitSalesReportRow>> GetFruitSalesReportAsync(DateTime fromDate, DateTime toDate)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            SELECT f.FruitName, f.Unit, SUM(si.Quantity) AS TotalQuantity, SUM(si.TotalAmount) AS TotalAmount
            FROM dbo.SupplyItems si
            INNER JOIN dbo.FruitMaster f ON f.FruitID = si.FruitID
            INNER JOIN dbo.Supply s ON s.SupplyID = si.SupplyID
            WHERE s.SupplyDate BETWEEN @FromDate AND @ToDate
            GROUP BY f.FruitName, f.Unit
            ORDER BY TotalAmount DESC;
            """;
        var result = await connection.QueryAsync<FruitSalesReportRow>(sql, new { FromDate = fromDate, ToDate = toDate });
        return result.ToList();
    }

    public async Task<List<OutstandingReportRow>> GetOutstandingReportAsync()
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            SELECT sh.ShopName AS Name, 'Customer' AS Type, ISNULL(latest.RunningBalance, sh.OpeningBalance) AS OutstandingAmount
            FROM dbo.ShopMaster sh
            OUTER APPLY (
                SELECT TOP 1 RunningBalance FROM dbo.ShopLedger sl
                WHERE sl.ShopID = sh.ShopID ORDER BY sl.TransactionDate DESC, sl.LedgerID DESC
            ) latest
            WHERE sh.IsActive = 1

            UNION ALL

            SELECT s.SupplierName AS Name, 'Supplier' AS Type, ISNULL(latest.RunningBalance, s.OpeningBalance) AS OutstandingAmount
            FROM dbo.SupplierMaster s
            OUTER APPLY (
                SELECT TOP 1 RunningBalance FROM dbo.SupplierLedger spl
                WHERE spl.SupplierID = s.SupplierID ORDER BY spl.TransactionDate DESC, spl.LedgerID DESC
            ) latest
            WHERE s.IsActive = 1
            ORDER BY Type, OutstandingAmount DESC;
            """;
        var result = await connection.QueryAsync<OutstandingReportRow>(sql);
        return result.ToList();
    }

    public async Task<List<ProfitSummaryReportRow>> GetProfitSummaryAsync(DateTime fromDate, DateTime toDate)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            ;WITH MonthSeries AS
            (
                SELECT DATEFROMPARTS(YEAR(@FromDate), MONTH(@FromDate), 1) AS MonthStart
                UNION ALL
                SELECT DATEADD(MONTH, 1, MonthStart)
                FROM MonthSeries
                WHERE DATEADD(MONTH, 1, MonthStart) <= DATEFROMPARTS(YEAR(@ToDate), MONTH(@ToDate), 1)
            )
            SELECT
                FORMAT(d.MonthStart, 'yyyy-MM') AS Month,
                ISNULL(sales.Total, 0) AS TotalSales,
                ISNULL(purchases.Total, 0) AS TotalPurchases,
                ISNULL(expenses.Total, 0) AS TotalExpenses,
                ISNULL(sales.Total, 0) - ISNULL(purchases.Total, 0) - ISNULL(expenses.Total, 0) AS NetProfit
            FROM MonthSeries d
            LEFT JOIN (
                SELECT DATEFROMPARTS(YEAR(SupplyDate), MONTH(SupplyDate), 1) AS MonthStart, SUM(TotalAmount) AS Total
                FROM dbo.Supply WHERE SupplyDate BETWEEN @FromDate AND @ToDate
                GROUP BY DATEFROMPARTS(YEAR(SupplyDate), MONTH(SupplyDate), 1)
            ) sales ON sales.MonthStart = d.MonthStart
            LEFT JOIN (
                SELECT DATEFROMPARTS(YEAR(PurchaseDate), MONTH(PurchaseDate), 1) AS MonthStart, SUM(TotalAmount) AS Total
                FROM dbo.Purchase WHERE PurchaseDate BETWEEN @FromDate AND @ToDate
                GROUP BY DATEFROMPARTS(YEAR(PurchaseDate), MONTH(PurchaseDate), 1)
            ) purchases ON purchases.MonthStart = d.MonthStart
            LEFT JOIN (
                SELECT DATEFROMPARTS(YEAR(ExpenseDate), MONTH(ExpenseDate), 1) AS MonthStart, SUM(Amount) AS Total
                FROM dbo.DailyExpense WHERE ExpenseDate BETWEEN @FromDate AND @ToDate
                GROUP BY DATEFROMPARTS(YEAR(ExpenseDate), MONTH(ExpenseDate), 1)
            ) expenses ON expenses.MonthStart = d.MonthStart
            ORDER BY d.MonthStart
            OPTION (MAXRECURSION 120);
            """;
        var result = await connection.QueryAsync<ProfitSummaryReportRow>(sql, new { FromDate = fromDate, ToDate = toDate });
        return result.ToList();
    }

    public async Task<List<ExpenseByCategoryReportRow>> GetExpenseByCategoryAsync(DateTime fromDate, DateTime toDate)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            SELECT c.CategoryName, SUM(e.Amount) AS TotalAmount
            FROM dbo.DailyExpense e
            INNER JOIN dbo.ExpenseCategory c ON c.ExpenseCategoryID = e.ExpenseCategoryID
            WHERE e.ExpenseDate BETWEEN @FromDate AND @ToDate
            GROUP BY c.CategoryName
            ORDER BY TotalAmount DESC;
            """;
        var result = await connection.QueryAsync<ExpenseByCategoryReportRow>(sql, new { FromDate = fromDate, ToDate = toDate });
        return result.ToList();
    }

    public async Task<List<SalaryByEmployeeReportRow>> GetSalaryByEmployeeAsync(DateTime fromDate, DateTime toDate, int? employeeId)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            SELECT emp.EmployeeID, emp.FullName AS EmployeeName, COUNT(*) AS WorkDaysCount, SUM(w.Amount) AS TotalAmount
            FROM dbo.EmployeeWorkLog w
            INNER JOIN dbo.EmployeeMaster emp ON emp.EmployeeID = w.EmployeeID
            WHERE w.WorkDate BETWEEN @FromDate AND @ToDate
              AND (@EmployeeID IS NULL OR w.EmployeeID = @EmployeeID)
            GROUP BY emp.EmployeeID, emp.FullName
            ORDER BY TotalAmount DESC;
            """;
        var result = await connection.QueryAsync<SalaryByEmployeeReportRow>(sql, new { FromDate = fromDate, ToDate = toDate, EmployeeID = employeeId });
        return result.ToList();
    }
}
