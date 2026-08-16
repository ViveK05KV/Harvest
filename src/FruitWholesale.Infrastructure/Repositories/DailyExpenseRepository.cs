using System.Data;
using Dapper;
using FruitWholesale.Application.Common.Interfaces;
using FruitWholesale.Domain.Entities;
using FruitWholesale.Domain.Enums;
using FruitWholesale.Shared.Pagination;

namespace FruitWholesale.Infrastructure.Repositories;

public class DailyExpenseRepository(IDbConnectionFactory connectionFactory, ILedgerService ledgerService) : IDailyExpenseRepository
{
    public async Task<DailyExpense?> GetByIdAsync(int expenseId)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            SELECT e.*, c.CategoryName FROM DailyExpense e
            INNER JOIN ExpenseCategory c ON c.ExpenseCategoryID = e.ExpenseCategoryID
            WHERE e.ExpenseID = @ExpenseID;
            """;
        return await connection.QueryFirstOrDefaultAsync<DailyExpense>(sql, new { ExpenseID = expenseId });
    }

    public async Task<PaginatedList<DailyExpense>> GetPagedAsync(PaginationRequest request, int? expenseCategoryId, DateTime? fromDate, DateTime? toDate)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            SELECT COUNT(*) FROM DailyExpense e
            INNER JOIN ExpenseCategory c ON c.ExpenseCategoryID = e.ExpenseCategoryID
            WHERE (@ExpenseCategoryID::int IS NULL OR e.ExpenseCategoryID = @ExpenseCategoryID)
              AND (@FromDate::timestamp IS NULL OR e.ExpenseDate >= @FromDate)
              AND (@ToDate::timestamp IS NULL OR e.ExpenseDate <= @ToDate)
              AND (@SearchTerm::text IS NULL OR e.PaidTo ILIKE @SearchPattern OR c.CategoryName ILIKE @SearchPattern);

            SELECT e.*, c.CategoryName FROM DailyExpense e
            INNER JOIN ExpenseCategory c ON c.ExpenseCategoryID = e.ExpenseCategoryID
            WHERE (@ExpenseCategoryID::int IS NULL OR e.ExpenseCategoryID = @ExpenseCategoryID)
              AND (@FromDate::timestamp IS NULL OR e.ExpenseDate >= @FromDate)
              AND (@ToDate::timestamp IS NULL OR e.ExpenseDate <= @ToDate)
              AND (@SearchTerm::text IS NULL OR e.PaidTo ILIKE @SearchPattern OR c.CategoryName ILIKE @SearchPattern)
            ORDER BY e.ExpenseDate DESC, e.ExpenseID DESC
            OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;
            """;
        using var multi = await connection.QueryMultipleAsync(sql, new
        {
            ExpenseCategoryID = expenseCategoryId,
            FromDate = fromDate,
            ToDate = toDate,
            SearchTerm = request.SearchTerm,
            SearchPattern = $"%{request.SearchTerm}%",
            request.Offset,
            request.PageSize
        });
        var total = await multi.ReadSingleAsync<int>();
        var items = (await multi.ReadAsync<DailyExpense>()).ToList();
        return new PaginatedList<DailyExpense>(items, total, request.PageNumber, request.PageSize);
    }

    public async Task<int> CreateAsync(DailyExpense expense)
    {
        using var connection = connectionFactory.CreateConnection();
        connection.Open();
        using var transaction = connection.BeginTransaction();
        try
        {
            const string insertSql = """
                INSERT INTO DailyExpense (ExpenseDate, ExpenseCategoryID, Amount, PaymentMode, PaidTo, Description, CreatedBy)
                VALUES (@ExpenseDate, @ExpenseCategoryID, @Amount, @PaymentMode, @PaidTo, @Description, @CreatedBy)
                RETURNING ExpenseID;
                """;
            var expenseId = await connection.QuerySingleAsync<int>(insertSql, expense, transaction);

            await ledgerService.AddCashLedgerEntryAsync(connection, transaction, expense.ExpenseDate,
                LedgerTransactionTypes.DailyExpense, ReferenceTables.DailyExpense, expenseId, expense.PaymentMode,
                0, expense.Amount, await ExpenseNarrationAsync(connection, transaction, expense));
            await ledgerService.RecalculateCashLedgerAsync(connection, transaction);

            transaction.Commit();
            return expenseId;
        }
        catch
        {
            transaction.Rollback();
            throw;
        }
    }

    public async Task UpdateAsync(DailyExpense expense)
    {
        using var connection = connectionFactory.CreateConnection();
        connection.Open();
        using var transaction = connection.BeginTransaction();
        try
        {
            const string updateSql = """
                UPDATE DailyExpense
                SET ExpenseDate = @ExpenseDate, ExpenseCategoryID = @ExpenseCategoryID, Amount = @Amount,
                    PaymentMode = @PaymentMode, PaidTo = @PaidTo, Description = @Description, UpdatedAt = (now() AT TIME ZONE 'utc')
                WHERE ExpenseID = @ExpenseID;
                """;
            await connection.ExecuteAsync(updateSql, expense, transaction);

            await ledgerService.RemoveCashLedgerEntriesForReferenceAsync(connection, transaction, ReferenceTables.DailyExpense, expense.ExpenseID);
            await ledgerService.AddCashLedgerEntryAsync(connection, transaction, expense.ExpenseDate,
                LedgerTransactionTypes.DailyExpense, ReferenceTables.DailyExpense, expense.ExpenseID, expense.PaymentMode,
                0, expense.Amount, await ExpenseNarrationAsync(connection, transaction, expense));
            await ledgerService.RecalculateCashLedgerAsync(connection, transaction);

            transaction.Commit();
        }
        catch
        {
            transaction.Rollback();
            throw;
        }
    }

    public async Task DeleteAsync(int expenseId)
    {
        using var connection = connectionFactory.CreateConnection();
        connection.Open();
        using var transaction = connection.BeginTransaction();
        try
        {
            await ledgerService.RemoveCashLedgerEntriesForReferenceAsync(connection, transaction, ReferenceTables.DailyExpense, expenseId);
            await connection.ExecuteAsync("DELETE FROM DailyExpense WHERE ExpenseID = @ExpenseID", new { ExpenseID = expenseId }, transaction);
            await ledgerService.RecalculateCashLedgerAsync(connection, transaction);

            transaction.Commit();
        }
        catch
        {
            transaction.Rollback();
            throw;
        }
    }

    // The Cash Ledger mixes every expense category together, so its narration needs the actual
    // category ("Fuel Expense", "Office Expense", ...) rather than the generic "Expense:" prefix -
    // ExpenseCategoryID alone means nothing on a ledger row. PaidTo is appended when present for
    // extra context (who the cash actually went to), but the category name is the headline.
    private static async Task<string> ExpenseNarrationAsync(IDbConnection connection, IDbTransaction transaction, DailyExpense expense)
    {
        var categoryName = await connection.QueryFirstOrDefaultAsync<string>(
            "SELECT CategoryName FROM ExpenseCategory WHERE ExpenseCategoryID = @ExpenseCategoryID",
            new { expense.ExpenseCategoryID }, transaction) ?? "Expense";
        return string.IsNullOrWhiteSpace(expense.PaidTo) ? categoryName : $"{categoryName} - {expense.PaidTo}";
    }
}
