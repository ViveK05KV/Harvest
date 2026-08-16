using Dapper;
using FruitWholesale.Application.Common.Interfaces;
using FruitWholesale.Domain.Entities;
using FruitWholesale.Domain.Enums;
using FruitWholesale.Shared.Pagination;

namespace FruitWholesale.Infrastructure.Repositories;

public class EmployeeWorkLogRepository(IDbConnectionFactory connectionFactory, ILedgerService ledgerService) : IEmployeeWorkLogRepository
{
    public async Task<EmployeeWorkLog?> GetByIdAsync(int employeeWorkLogId)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            SELECT w.*, e.FullName AS EmployeeName, r.RouteName FROM EmployeeWorkLog w
            INNER JOIN EmployeeMaster e ON e.EmployeeID = w.EmployeeID
            LEFT JOIN RouteMaster r ON r.RouteID = w.RouteID
            WHERE w.EmployeeWorkLogID = @EmployeeWorkLogID;
            """;
        return await connection.QueryFirstOrDefaultAsync<EmployeeWorkLog>(sql, new { EmployeeWorkLogID = employeeWorkLogId });
    }

    public async Task<PaginatedList<EmployeeWorkLog>> GetPagedAsync(PaginationRequest request, int? employeeId, DateTime? fromDate, DateTime? toDate)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            SELECT COUNT(*) FROM EmployeeWorkLog w
            INNER JOIN EmployeeMaster e ON e.EmployeeID = w.EmployeeID
            WHERE (@EmployeeID::int IS NULL OR w.EmployeeID = @EmployeeID)
              AND (@FromDate::date IS NULL OR w.WorkDate >= @FromDate)
              AND (@ToDate::date IS NULL OR w.WorkDate <= @ToDate)
              AND (@SearchTerm::text IS NULL OR e.FullName ILIKE @SearchPattern);

            SELECT w.*, e.FullName AS EmployeeName, r.RouteName FROM EmployeeWorkLog w
            INNER JOIN EmployeeMaster e ON e.EmployeeID = w.EmployeeID
            LEFT JOIN RouteMaster r ON r.RouteID = w.RouteID
            WHERE (@EmployeeID::int IS NULL OR w.EmployeeID = @EmployeeID)
              AND (@FromDate::date IS NULL OR w.WorkDate >= @FromDate)
              AND (@ToDate::date IS NULL OR w.WorkDate <= @ToDate)
              AND (@SearchTerm::text IS NULL OR e.FullName ILIKE @SearchPattern)
            ORDER BY w.WorkDate DESC, w.EmployeeWorkLogID DESC
            OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;
            """;
        using var multi = await connection.QueryMultipleAsync(sql, new
        {
            EmployeeID = employeeId,
            FromDate = fromDate,
            ToDate = toDate,
            SearchTerm = request.SearchTerm,
            SearchPattern = $"%{request.SearchTerm}%",
            request.Offset,
            request.PageSize
        });
        var total = await multi.ReadSingleAsync<int>();
        var items = (await multi.ReadAsync<EmployeeWorkLog>()).ToList();
        return new PaginatedList<EmployeeWorkLog>(items, total, request.PageNumber, request.PageSize);
    }

    public async Task<int> CreateAsync(EmployeeWorkLog workLog)
    {
        using var connection = connectionFactory.CreateConnection();
        connection.Open();
        using var transaction = connection.BeginTransaction();
        try
        {
            const string insertSql = """
                INSERT INTO EmployeeWorkLog (WorkDate, EmployeeID, JobType, RouteID, Amount, PaymentMode, Remarks, CreatedBy)
                VALUES (@WorkDate, @EmployeeID, @JobType, @RouteID, @Amount, @PaymentMode, @Remarks, @CreatedBy)
                RETURNING EmployeeWorkLogID;
                """;
            var workLogId = await connection.QuerySingleAsync<int>(insertSql, workLog, transaction);

            if (workLog.Amount > 0)
            {
                await ledgerService.AddCashLedgerEntryAsync(connection, transaction, workLog.WorkDate,
                    LedgerTransactionTypes.EmployeeWorkLog, ReferenceTables.EmployeeWorkLog, workLogId, workLog.PaymentMode,
                    0, workLog.Amount, $"Salary ({workLog.JobType})");
                await ledgerService.RecalculateCashLedgerAsync(connection, transaction);
            }

            transaction.Commit();
            return workLogId;
        }
        catch
        {
            transaction.Rollback();
            throw;
        }
    }

    public async Task UpdateAsync(EmployeeWorkLog workLog)
    {
        using var connection = connectionFactory.CreateConnection();
        connection.Open();
        using var transaction = connection.BeginTransaction();
        try
        {
            const string updateSql = """
                UPDATE EmployeeWorkLog
                SET WorkDate = @WorkDate, EmployeeID = @EmployeeID, JobType = @JobType, RouteID = @RouteID,
                    Amount = @Amount, PaymentMode = @PaymentMode, Remarks = @Remarks, UpdatedAt = (now() AT TIME ZONE 'utc')
                WHERE EmployeeWorkLogID = @EmployeeWorkLogID;
                """;
            await connection.ExecuteAsync(updateSql, workLog, transaction);

            await ledgerService.RemoveCashLedgerEntriesForReferenceAsync(connection, transaction, ReferenceTables.EmployeeWorkLog, workLog.EmployeeWorkLogID);
            if (workLog.Amount > 0)
            {
                await ledgerService.AddCashLedgerEntryAsync(connection, transaction, workLog.WorkDate,
                    LedgerTransactionTypes.EmployeeWorkLog, ReferenceTables.EmployeeWorkLog, workLog.EmployeeWorkLogID, workLog.PaymentMode,
                    0, workLog.Amount, $"Salary ({workLog.JobType})");
            }
            await ledgerService.RecalculateCashLedgerAsync(connection, transaction);

            transaction.Commit();
        }
        catch
        {
            transaction.Rollback();
            throw;
        }
    }

    public async Task DeleteAsync(int employeeWorkLogId)
    {
        using var connection = connectionFactory.CreateConnection();
        connection.Open();
        using var transaction = connection.BeginTransaction();
        try
        {
            await ledgerService.RemoveCashLedgerEntriesForReferenceAsync(connection, transaction, ReferenceTables.EmployeeWorkLog, employeeWorkLogId);
            await connection.ExecuteAsync("DELETE FROM EmployeeWorkLog WHERE EmployeeWorkLogID = @EmployeeWorkLogID", new { EmployeeWorkLogID = employeeWorkLogId }, transaction);
            await ledgerService.RecalculateCashLedgerAsync(connection, transaction);

            transaction.Commit();
        }
        catch
        {
            transaction.Rollback();
            throw;
        }
    }
}
