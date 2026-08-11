using Dapper;
using FruitWholesale.Application.Common.Interfaces;
using FruitWholesale.Domain.Entities;
using FruitWholesale.Shared.Pagination;

namespace FruitWholesale.Infrastructure.Repositories;

public class EmployeeRepository(IDbConnectionFactory connectionFactory) : IEmployeeRepository
{
    public async Task<Employee?> GetByIdAsync(int employeeId)
    {
        using var connection = connectionFactory.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<Employee>(
            "SELECT * FROM dbo.EmployeeMaster WHERE EmployeeID = @EmployeeID", new { EmployeeID = employeeId });
    }

    public async Task<IReadOnlyList<Employee>> GetAllActiveAsync()
    {
        using var connection = connectionFactory.CreateConnection();
        var result = await connection.QueryAsync<Employee>(
            "SELECT * FROM dbo.EmployeeMaster WHERE IsActive = 1 ORDER BY FullName");
        return result.ToList();
    }

    public async Task<PaginatedList<Employee>> GetPagedAsync(PaginationRequest request)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            SELECT COUNT(*) FROM dbo.EmployeeMaster
            WHERE (@SearchTerm IS NULL OR FullName LIKE @SearchPattern OR Phone LIKE @SearchPattern);

            SELECT * FROM dbo.EmployeeMaster
            WHERE (@SearchTerm IS NULL OR FullName LIKE @SearchPattern OR Phone LIKE @SearchPattern)
            ORDER BY
                CASE WHEN @SortBy = 'fullName' AND @SortDescending = 0 THEN FullName END ASC,
                CASE WHEN @SortBy = 'fullName' AND @SortDescending = 1 THEN FullName END DESC,
                CASE WHEN @SortBy IS NULL OR @SortBy <> 'fullName' THEN FullName END ASC
            OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;
            """;
        using var multi = await connection.QueryMultipleAsync(sql, new
        {
            SearchTerm = request.SearchTerm,
            SearchPattern = $"%{request.SearchTerm}%",
            request.SortBy,
            request.SortDescending,
            request.Offset,
            request.PageSize
        });
        var total = await multi.ReadSingleAsync<int>();
        var items = (await multi.ReadAsync<Employee>()).ToList();
        return new PaginatedList<Employee>(items, total, request.PageNumber, request.PageSize);
    }

    public async Task<int> CreateAsync(Employee employee)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            INSERT INTO dbo.EmployeeMaster (FullName, Phone, Address, IsActive)
            OUTPUT INSERTED.EmployeeID
            VALUES (@FullName, @Phone, @Address, @IsActive);
            """;
        return await connection.QuerySingleAsync<int>(sql, employee);
    }

    public async Task UpdateAsync(Employee employee)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            UPDATE dbo.EmployeeMaster
            SET FullName = @FullName, Phone = @Phone, Address = @Address, UpdatedAt = SYSUTCDATETIME()
            WHERE EmployeeID = @EmployeeID;
            """;
        await connection.ExecuteAsync(sql, employee);
    }

    public async Task SetActiveAsync(int employeeId, bool isActive)
    {
        using var connection = connectionFactory.CreateConnection();
        await connection.ExecuteAsync(
            "UPDATE dbo.EmployeeMaster SET IsActive = @IsActive, UpdatedAt = SYSUTCDATETIME() WHERE EmployeeID = @EmployeeID",
            new { EmployeeID = employeeId, IsActive = isActive });
    }
}
