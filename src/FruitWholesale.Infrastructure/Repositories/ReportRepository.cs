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
            FROM Supply s
            INNER JOIN ShopMaster sh ON sh.ShopID = s.ShopID
            WHERE s.SupplyDate BETWEEN @FromDate AND @ToDate
              AND (@ShopID::int IS NULL OR s.ShopID = @ShopID)
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
            FROM Collections c
            INNER JOIN ShopMaster sh ON sh.ShopID = c.ShopID
            WHERE c.CollectionDate BETWEEN @FromDate AND @ToDate
              AND (@ShopID::int IS NULL OR c.ShopID = @ShopID)
            ORDER BY c.CollectionDate;
            """;
        var result = await connection.QueryAsync<DailyCollectionReportRow>(sql, new { FromDate = fromDate, ToDate = toDate, ShopID = shopId });
        return result.ToList();
    }

    public async Task<List<DailyExpenseReportRow>> GetDailyExpenseAsync(DateTime fromDate, DateTime toDate, int? expenseCategoryId)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            SELECT e.ExpenseDate, c.CategoryName, e.Amount, COALESCE(e.PaidTo, '') AS PaidTo, e.PaymentMode
            FROM DailyExpense e
            INNER JOIN ExpenseCategory c ON c.ExpenseCategoryID = e.ExpenseCategoryID
            WHERE e.ExpenseDate BETWEEN @FromDate AND @ToDate
              AND (@ExpenseCategoryID::int IS NULL OR e.ExpenseCategoryID = @ExpenseCategoryID)
            ORDER BY e.ExpenseDate;
            """;
        var result = await connection.QueryAsync<DailyExpenseReportRow>(sql, new { FromDate = fromDate, ToDate = toDate, ExpenseCategoryID = expenseCategoryId });
        return result.ToList();
    }

    /// <summary>Salary paid, shaped as DailyExpenseReportRow so it can merge into the
    /// same Expense tab listing as DailyExpense rows.</summary>
    public async Task<List<DailyExpenseReportRow>> GetDailySalaryAsync(DateTime fromDate, DateTime toDate)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            SELECT w.WorkDate AS ExpenseDate, 'Salary Paid' AS CategoryName, w.Amount, emp.FullName AS PaidTo, w.PaymentMode
            FROM EmployeeWorkLog w
            INNER JOIN EmployeeMaster emp ON emp.EmployeeID = w.EmployeeID
            WHERE w.WorkDate BETWEEN @FromDate AND @ToDate
            ORDER BY w.WorkDate;
            """;
        var result = await connection.QueryAsync<DailyExpenseReportRow>(sql, new { FromDate = fromDate, ToDate = toDate });
        return result.ToList();
    }

    public async Task<List<PurchaseReportRow>> GetPurchaseReportAsync(DateTime fromDate, DateTime toDate, int? supplierId)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            SELECT p.PurchaseDate, p.InvoiceNo, s.SupplierName, p.TotalAmount
            FROM Purchase p
            INNER JOIN SupplierMaster s ON s.SupplierID = p.SupplierID
            WHERE p.PurchaseDate BETWEEN @FromDate AND @ToDate
              AND (@SupplierID::int IS NULL OR p.SupplierID = @SupplierID)
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
            FROM SupplyItems si
            INNER JOIN FruitMaster f ON f.FruitID = si.FruitID
            INNER JOIN Supply s ON s.SupplyID = si.SupplyID
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
            SELECT sh.ShopName AS Name, 'Customer' AS Type, COALESCE(latest.RunningBalance, sh.OpeningBalance) AS OutstandingAmount
            FROM ShopMaster sh
            LEFT JOIN LATERAL (
                SELECT RunningBalance FROM ShopLedger sl
                WHERE sl.ShopID = sh.ShopID ORDER BY sl.TransactionDate DESC, sl.LedgerID DESC LIMIT 1
            ) latest ON TRUE
            WHERE sh.IsActive = TRUE

            UNION ALL

            SELECT s.SupplierName AS Name, 'Supplier' AS Type, COALESCE(latest.RunningBalance, s.OpeningBalance) AS OutstandingAmount
            FROM SupplierMaster s
            LEFT JOIN LATERAL (
                SELECT RunningBalance FROM SupplierLedger spl
                WHERE spl.SupplierID = s.SupplierID ORDER BY spl.TransactionDate DESC, spl.LedgerID DESC LIMIT 1
            ) latest ON TRUE
            WHERE s.IsActive = TRUE
            ORDER BY Type, OutstandingAmount DESC;
            """;
        var result = await connection.QueryAsync<OutstandingReportRow>(sql);
        return result.ToList();
    }

    public async Task<List<ProfitSummaryReportRow>> GetProfitSummaryAsync(DateTime fromDate, DateTime toDate)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            WITH MonthSeries AS
            (
                SELECT generate_series(
                    DATE_TRUNC('month', @FromDate::date),
                    DATE_TRUNC('month', @ToDate::date),
                    INTERVAL '1 month'
                )::date AS MonthStart
            )
            SELECT
                TO_CHAR(d.MonthStart, 'YYYY-MM') AS Month,
                COALESCE(sales.Total, 0) AS TotalSales,
                COALESCE(purchases.Total, 0) AS TotalPurchases,
                COALESCE(expenses.Total, 0) AS TotalExpenses,
                COALESCE(sales.Total, 0) - COALESCE(purchases.Total, 0) - COALESCE(expenses.Total, 0) AS NetProfit
            FROM MonthSeries d
            LEFT JOIN (
                SELECT DATE_TRUNC('month', SupplyDate)::date AS MonthStart, SUM(TotalAmount) AS Total
                FROM Supply WHERE SupplyDate BETWEEN @FromDate AND @ToDate
                GROUP BY DATE_TRUNC('month', SupplyDate)
            ) sales ON sales.MonthStart = d.MonthStart
            LEFT JOIN (
                SELECT DATE_TRUNC('month', PurchaseDate)::date AS MonthStart, SUM(TotalAmount) AS Total
                FROM Purchase WHERE PurchaseDate BETWEEN @FromDate AND @ToDate
                GROUP BY DATE_TRUNC('month', PurchaseDate)
            ) purchases ON purchases.MonthStart = d.MonthStart
            LEFT JOIN (
                SELECT DATE_TRUNC('month', ExpenseDate)::date AS MonthStart, SUM(Amount) AS Total
                FROM DailyExpense WHERE ExpenseDate BETWEEN @FromDate AND @ToDate
                GROUP BY DATE_TRUNC('month', ExpenseDate)
            ) expenses ON expenses.MonthStart = d.MonthStart
            ORDER BY d.MonthStart;
            """;
        var result = await connection.QueryAsync<ProfitSummaryReportRow>(sql, new { FromDate = fromDate, ToDate = toDate });
        return result.ToList();
    }

    public async Task<List<ExpenseByCategoryReportRow>> GetExpenseByCategoryAsync(DateTime fromDate, DateTime toDate)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            SELECT c.CategoryName, SUM(e.Amount) AS TotalAmount
            FROM DailyExpense e
            INNER JOIN ExpenseCategory c ON c.ExpenseCategoryID = e.ExpenseCategoryID
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
            FROM EmployeeWorkLog w
            INNER JOIN EmployeeMaster emp ON emp.EmployeeID = w.EmployeeID
            WHERE w.WorkDate BETWEEN @FromDate AND @ToDate
              AND (@EmployeeID::int IS NULL OR w.EmployeeID = @EmployeeID)
            GROUP BY emp.EmployeeID, emp.FullName
            ORDER BY TotalAmount DESC;
            """;
        var result = await connection.QueryAsync<SalaryByEmployeeReportRow>(sql, new { FromDate = fromDate, ToDate = toDate, EmployeeID = employeeId });
        return result.ToList();
    }
}
