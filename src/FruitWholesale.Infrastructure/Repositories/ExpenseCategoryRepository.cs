using Dapper;
using FruitWholesale.Application.Common.Interfaces;
using FruitWholesale.Domain.Entities;
using FruitWholesale.Shared.Pagination;

namespace FruitWholesale.Infrastructure.Repositories;

public class ExpenseCategoryRepository(IDbConnectionFactory connectionFactory) : IExpenseCategoryRepository
{
    public async Task<ExpenseCategory?> GetByIdAsync(int expenseCategoryId)
    {
        using var connection = connectionFactory.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<ExpenseCategory>(
            "SELECT * FROM dbo.ExpenseCategory WHERE ExpenseCategoryID = @ExpenseCategoryID", new { ExpenseCategoryID = expenseCategoryId });
    }

    public async Task<IReadOnlyList<ExpenseCategory>> GetAllActiveAsync()
    {
        using var connection = connectionFactory.CreateConnection();
        var result = await connection.QueryAsync<ExpenseCategory>(
            "SELECT * FROM dbo.ExpenseCategory WHERE IsActive = 1 ORDER BY CategoryName");
        return result.ToList();
    }

    public async Task<PaginatedList<ExpenseCategory>> GetPagedAsync(PaginationRequest request)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            SELECT COUNT(*) FROM dbo.ExpenseCategory WHERE (@SearchTerm IS NULL OR CategoryName LIKE @SearchPattern);

            SELECT * FROM dbo.ExpenseCategory
            WHERE (@SearchTerm IS NULL OR CategoryName LIKE @SearchPattern)
            ORDER BY CategoryName ASC
            OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;
            """;
        using var multi = await connection.QueryMultipleAsync(sql, new
        {
            SearchTerm = request.SearchTerm,
            SearchPattern = $"%{request.SearchTerm}%",
            request.Offset,
            request.PageSize
        });
        var total = await multi.ReadSingleAsync<int>();
        var items = (await multi.ReadAsync<ExpenseCategory>()).ToList();
        return new PaginatedList<ExpenseCategory>(items, total, request.PageNumber, request.PageSize);
    }

    public async Task<int> CreateAsync(ExpenseCategory category)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            INSERT INTO dbo.ExpenseCategory (CategoryName, Description, IsActive)
            OUTPUT INSERTED.ExpenseCategoryID
            VALUES (@CategoryName, @Description, @IsActive);
            """;
        return await connection.QuerySingleAsync<int>(sql, category);
    }

    public async Task UpdateAsync(ExpenseCategory category)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            UPDATE dbo.ExpenseCategory SET CategoryName = @CategoryName, Description = @Description
            WHERE ExpenseCategoryID = @ExpenseCategoryID;
            """;
        await connection.ExecuteAsync(sql, category);
    }

    public async Task SetActiveAsync(int expenseCategoryId, bool isActive)
    {
        using var connection = connectionFactory.CreateConnection();
        await connection.ExecuteAsync(
            "UPDATE dbo.ExpenseCategory SET IsActive = @IsActive WHERE ExpenseCategoryID = @ExpenseCategoryID",
            new { ExpenseCategoryID = expenseCategoryId, IsActive = isActive });
    }
}
