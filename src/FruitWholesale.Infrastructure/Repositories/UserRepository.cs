using Dapper;
using FruitWholesale.Application.Common.Interfaces;
using FruitWholesale.Domain.Entities;
using FruitWholesale.Shared.Pagination;

namespace FruitWholesale.Infrastructure.Repositories;

public class UserRepository(IDbConnectionFactory connectionFactory) : IUserRepository
{
    public async Task<User?> GetByIdAsync(int userId)
    {
        using var connection = connectionFactory.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<User>(
            "SELECT * FROM dbo.Users WHERE UserID = @UserID", new { UserID = userId });
    }

    public async Task<User?> GetByUsernameAsync(string username)
    {
        using var connection = connectionFactory.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<User>(
            "SELECT * FROM dbo.Users WHERE Username = @Username", new { Username = username });
    }

    public async Task<PaginatedList<User>> GetPagedAsync(PaginationRequest request)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            SELECT COUNT(*) FROM dbo.Users
            WHERE (@SearchTerm IS NULL OR FullName LIKE @SearchPattern OR Username LIKE @SearchPattern);

            SELECT * FROM dbo.Users
            WHERE (@SearchTerm IS NULL OR FullName LIKE @SearchPattern OR Username LIKE @SearchPattern)
            ORDER BY
                CASE WHEN @SortBy = 'FullName' AND @SortDescending = 0 THEN FullName END ASC,
                CASE WHEN @SortBy = 'FullName' AND @SortDescending = 1 THEN FullName END DESC,
                CASE WHEN @SortBy IS NULL OR @SortBy <> 'FullName' THEN UserID END DESC
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
        var items = (await multi.ReadAsync<User>()).ToList();
        return new PaginatedList<User>(items, total, request.PageNumber, request.PageSize);
    }

    public async Task<int> CreateAsync(User user)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            INSERT INTO dbo.Users (FullName, Username, PasswordHash, Role, IsActive)
            OUTPUT INSERTED.UserID
            VALUES (@FullName, @Username, @PasswordHash, @Role, @IsActive);
            """;
        return await connection.QuerySingleAsync<int>(sql, user);
    }

    public async Task UpdateAsync(User user)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            UPDATE dbo.Users
            SET FullName = @FullName, Role = @Role, UpdatedAt = SYSUTCDATETIME()
            WHERE UserID = @UserID;
            """;
        await connection.ExecuteAsync(sql, user);
    }

    public async Task SetActiveAsync(int userId, bool isActive)
    {
        using var connection = connectionFactory.CreateConnection();
        await connection.ExecuteAsync(
            "UPDATE dbo.Users SET IsActive = @IsActive, UpdatedAt = SYSUTCDATETIME() WHERE UserID = @UserID",
            new { UserID = userId, IsActive = isActive });
    }

    public async Task<bool> UsernameExistsAsync(string username, int? excludeUserId = null)
    {
        using var connection = connectionFactory.CreateConnection();
        return await connection.ExecuteScalarAsync<bool>(
            "SELECT CASE WHEN EXISTS (SELECT 1 FROM dbo.Users WHERE Username = @Username AND (@ExcludeUserId IS NULL OR UserID <> @ExcludeUserId)) THEN 1 ELSE 0 END",
            new { Username = username, ExcludeUserId = excludeUserId });
    }

    public async Task ChangePasswordAsync(int userId, string newPasswordHash)
    {
        using var connection = connectionFactory.CreateConnection();
        await connection.ExecuteAsync(
            "UPDATE dbo.Users SET PasswordHash = @PasswordHash, UpdatedAt = SYSUTCDATETIME() WHERE UserID = @UserID",
            new { UserID = userId, PasswordHash = newPasswordHash });
    }
}
