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
            "SELECT * FROM Users WHERE UserID = @UserID", new { UserID = userId });
    }

    public async Task<User?> GetByUsernameAsync(string username)
    {
        using var connection = connectionFactory.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<User>(
            "SELECT * FROM Users WHERE Username = @Username", new { Username = username });
    }

    public async Task<PaginatedList<User>> GetPagedAsync(PaginationRequest request)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            SELECT COUNT(*) FROM Users
            WHERE (@SearchTerm::text IS NULL OR FullName ILIKE @SearchPattern OR Username ILIKE @SearchPattern);

            SELECT * FROM Users
            WHERE (@SearchTerm::text IS NULL OR FullName ILIKE @SearchPattern OR Username ILIKE @SearchPattern)
            ORDER BY
                CASE WHEN @SortBy = 'FullName' AND NOT @SortDescending THEN FullName END ASC,
                CASE WHEN @SortBy = 'FullName' AND @SortDescending THEN FullName END DESC,
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
            INSERT INTO Users (FullName, Username, PasswordHash, Role, IsActive)
            VALUES (@FullName, @Username, @PasswordHash, @Role, @IsActive)
            RETURNING UserID;
            """;
        return await connection.QuerySingleAsync<int>(sql, user);
    }

    public async Task UpdateAsync(User user)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            UPDATE Users
            SET FullName = @FullName, Role = @Role, UpdatedAt = (now() AT TIME ZONE 'utc')
            WHERE UserID = @UserID;
            """;
        await connection.ExecuteAsync(sql, user);
    }

    public async Task SetActiveAsync(int userId, bool isActive)
    {
        using var connection = connectionFactory.CreateConnection();
        await connection.ExecuteAsync(
            "UPDATE Users SET IsActive = @IsActive, UpdatedAt = (now() AT TIME ZONE 'utc') WHERE UserID = @UserID",
            new { UserID = userId, IsActive = isActive });
    }

    public async Task<bool> UsernameExistsAsync(string username, int? excludeUserId = null)
    {
        using var connection = connectionFactory.CreateConnection();
        return await connection.ExecuteScalarAsync<bool>(
            "SELECT EXISTS (SELECT 1 FROM Users WHERE Username = @Username AND (@ExcludeUserId::int IS NULL OR UserID <> @ExcludeUserId))",
            new { Username = username, ExcludeUserId = excludeUserId });
    }

    public async Task ChangePasswordAsync(int userId, string newPasswordHash)
    {
        using var connection = connectionFactory.CreateConnection();
        await connection.ExecuteAsync(
            "UPDATE Users SET PasswordHash = @PasswordHash, UpdatedAt = (now() AT TIME ZONE 'utc') WHERE UserID = @UserID",
            new { UserID = userId, PasswordHash = newPasswordHash });
    }

    public async Task ChangeUsernameAsync(int userId, string newUsername)
    {
        using var connection = connectionFactory.CreateConnection();
        await connection.ExecuteAsync(
            "UPDATE Users SET Username = @Username, UpdatedAt = (now() AT TIME ZONE 'utc') WHERE UserID = @UserID",
            new { UserID = userId, Username = newUsername });
    }
}
