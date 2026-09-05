using Dapper;
using FruitWholesale.Application.Common.Interfaces;
using FruitWholesale.Application.DTOs.Employee;
using FruitWholesale.Domain.Entities;
using FruitWholesale.Domain.Enums;

namespace FruitWholesale.Infrastructure.Repositories;

public class EmployeeLoanRepository(IDbConnectionFactory connectionFactory, ILedgerService ledgerService) : IEmployeeLoanRepository
{
    public async Task<List<EmployeeMonthlyPayTotal>> GetMonthlyPayTotalsAsync(int employeeId)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            SELECT date_trunc('month', WorkDate) AS Month, SUM(Amount) AS TotalPaid, COUNT(DISTINCT WorkDate) AS DaysWorked
            FROM EmployeeWorkLog
            WHERE EmployeeID = @EmployeeID
            GROUP BY date_trunc('month', WorkDate)
            ORDER BY Month;
            """;
        var result = await connection.QueryAsync<EmployeeMonthlyPayTotal>(sql, new { EmployeeID = employeeId });
        return result.ToList();
    }

    public async Task<Dictionary<int, List<EmployeeMonthlyPayTotal>>> GetMonthlyPayTotalsBatchAsync()
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            SELECT EmployeeID, date_trunc('month', WorkDate) AS Month, SUM(Amount) AS TotalPaid, COUNT(DISTINCT WorkDate) AS DaysWorked
            FROM EmployeeWorkLog
            GROUP BY EmployeeID, date_trunc('month', WorkDate)
            ORDER BY EmployeeID, Month;
            """;
        var rows = await connection.QueryAsync<(int EmployeeID, DateTime Month, decimal TotalPaid, int DaysWorked)>(sql);
        return rows
            .GroupBy(r => r.EmployeeID)
            .ToDictionary(g => g.Key, g => g.Select(r => new EmployeeMonthlyPayTotal { Month = r.Month, TotalPaid = r.TotalPaid, DaysWorked = r.DaysWorked }).ToList());
    }

    public async Task<List<EmployeeLoanRepayment>> GetRepaymentsAsync(int employeeId)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            SELECT r.*, e.FullName AS EmployeeName FROM EmployeeLoanRepayment r
            INNER JOIN EmployeeMaster e ON e.EmployeeID = r.EmployeeID
            WHERE r.EmployeeID = @EmployeeID
            ORDER BY r.RepaymentDate, r.EmployeeLoanRepaymentID;
            """;
        var result = await connection.QueryAsync<EmployeeLoanRepayment>(sql, new { EmployeeID = employeeId });
        return result.ToList();
    }

    public async Task<Dictionary<int, decimal>> GetRepaymentTotalsBatchAsync()
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = "SELECT EmployeeID, SUM(Amount) AS Total FROM EmployeeLoanRepayment GROUP BY EmployeeID;";
        var rows = await connection.QueryAsync<(int EmployeeID, decimal Total)>(sql);
        return rows.ToDictionary(r => r.EmployeeID, r => r.Total);
    }

    public async Task<EmployeeLoanRepayment?> GetRepaymentByIdAsync(int employeeLoanRepaymentId)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            SELECT r.*, e.FullName AS EmployeeName FROM EmployeeLoanRepayment r
            INNER JOIN EmployeeMaster e ON e.EmployeeID = r.EmployeeID
            WHERE r.EmployeeLoanRepaymentID = @EmployeeLoanRepaymentID;
            """;
        return await connection.QueryFirstOrDefaultAsync<EmployeeLoanRepayment>(sql, new { EmployeeLoanRepaymentID = employeeLoanRepaymentId });
    }

    public async Task<int> CreateRepaymentAsync(EmployeeLoanRepayment repayment)
    {
        using var connection = connectionFactory.CreateConnection();
        connection.Open();
        using var transaction = connection.BeginTransaction();
        try
        {
            const string insertSql = """
                INSERT INTO EmployeeLoanRepayment (EmployeeID, RepaymentDate, Amount, PaymentMode, Remarks, CreatedBy)
                VALUES (@EmployeeID, @RepaymentDate, @Amount, @PaymentMode, @Remarks, @CreatedBy)
                RETURNING EmployeeLoanRepaymentID;
                """;
            var repaymentId = await connection.QuerySingleAsync<int>(insertSql, repayment, transaction);

            await ledgerService.AddCashLedgerEntryAsync(connection, transaction, repayment.RepaymentDate,
                LedgerTransactionTypes.LoanRepayment, ReferenceTables.EmployeeLoanRepayment, repaymentId, repayment.PaymentMode,
                repayment.Amount, 0, "Employee loan repayment");
            await ledgerService.RecalculateCashLedgerAsync(connection, transaction);

            transaction.Commit();
            return repaymentId;
        }
        catch
        {
            transaction.Rollback();
            throw;
        }
    }

    public async Task UpdateRepaymentAsync(EmployeeLoanRepayment repayment)
    {
        using var connection = connectionFactory.CreateConnection();
        connection.Open();
        using var transaction = connection.BeginTransaction();
        try
        {
            const string updateSql = """
                UPDATE EmployeeLoanRepayment
                SET EmployeeID = @EmployeeID, RepaymentDate = @RepaymentDate, Amount = @Amount,
                    PaymentMode = @PaymentMode, Remarks = @Remarks, UpdatedAt = (now() AT TIME ZONE 'utc')
                WHERE EmployeeLoanRepaymentID = @EmployeeLoanRepaymentID;
                """;
            await connection.ExecuteAsync(updateSql, repayment, transaction);

            await ledgerService.RemoveCashLedgerEntriesForReferenceAsync(connection, transaction, ReferenceTables.EmployeeLoanRepayment, repayment.EmployeeLoanRepaymentID);
            await ledgerService.AddCashLedgerEntryAsync(connection, transaction, repayment.RepaymentDate,
                LedgerTransactionTypes.LoanRepayment, ReferenceTables.EmployeeLoanRepayment, repayment.EmployeeLoanRepaymentID, repayment.PaymentMode,
                repayment.Amount, 0, "Employee loan repayment");
            await ledgerService.RecalculateCashLedgerAsync(connection, transaction);

            transaction.Commit();
        }
        catch
        {
            transaction.Rollback();
            throw;
        }
    }

    public async Task DeleteRepaymentAsync(int employeeLoanRepaymentId)
    {
        using var connection = connectionFactory.CreateConnection();
        connection.Open();
        using var transaction = connection.BeginTransaction();
        try
        {
            await ledgerService.RemoveCashLedgerEntriesForReferenceAsync(connection, transaction, ReferenceTables.EmployeeLoanRepayment, employeeLoanRepaymentId);
            await connection.ExecuteAsync("DELETE FROM EmployeeLoanRepayment WHERE EmployeeLoanRepaymentID = @EmployeeLoanRepaymentID", new { EmployeeLoanRepaymentID = employeeLoanRepaymentId }, transaction);
            await ledgerService.RecalculateCashLedgerAsync(connection, transaction);

            transaction.Commit();
        }
        catch
        {
            transaction.Rollback();
            throw;
        }
    }

    public async Task<List<EmployeeLoanAdjustment>> GetAdjustmentsAsync(int employeeId)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            SELECT * FROM EmployeeLoanAdjustment
            WHERE EmployeeID = @EmployeeID
            ORDER BY AdjustmentDate, EmployeeLoanAdjustmentID;
            """;
        var result = await connection.QueryAsync<EmployeeLoanAdjustment>(sql, new { EmployeeID = employeeId });
        return result.ToList();
    }

    public async Task<Dictionary<int, decimal>> GetAdjustmentTotalsBatchAsync()
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            SELECT EmployeeID, SUM(CASE WHEN IsIncrease THEN Amount ELSE -Amount END) AS Total
            FROM EmployeeLoanAdjustment
            GROUP BY EmployeeID;
            """;
        var rows = await connection.QueryAsync<(int EmployeeID, decimal Total)>(sql);
        return rows.ToDictionary(r => r.EmployeeID, r => r.Total);
    }

    public async Task<EmployeeLoanAdjustment?> GetAdjustmentByIdAsync(int employeeLoanAdjustmentId)
    {
        using var connection = connectionFactory.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<EmployeeLoanAdjustment>(
            "SELECT * FROM EmployeeLoanAdjustment WHERE EmployeeLoanAdjustmentID = @EmployeeLoanAdjustmentID",
            new { EmployeeLoanAdjustmentID = employeeLoanAdjustmentId });
    }

    public async Task<int> CreateAdjustmentAsync(EmployeeLoanAdjustment adjustment)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            INSERT INTO EmployeeLoanAdjustment (EmployeeID, AdjustmentDate, Amount, IsIncrease, Narration, CreatedBy)
            VALUES (@EmployeeID, @AdjustmentDate, @Amount, @IsIncrease, @Narration, @CreatedBy)
            RETURNING EmployeeLoanAdjustmentID;
            """;
        return await connection.QuerySingleAsync<int>(sql, adjustment);
    }

    public async Task DeleteAdjustmentAsync(int employeeLoanAdjustmentId)
    {
        using var connection = connectionFactory.CreateConnection();
        await connection.ExecuteAsync(
            "DELETE FROM EmployeeLoanAdjustment WHERE EmployeeLoanAdjustmentID = @EmployeeLoanAdjustmentID",
            new { EmployeeLoanAdjustmentID = employeeLoanAdjustmentId });
    }
}
