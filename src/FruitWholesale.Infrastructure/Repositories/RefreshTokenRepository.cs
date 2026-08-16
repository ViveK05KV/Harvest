using Dapper;
using FruitWholesale.Application.Common.Interfaces;
using FruitWholesale.Domain.Entities;

namespace FruitWholesale.Infrastructure.Repositories;

public class RefreshTokenRepository(IDbConnectionFactory connectionFactory) : IRefreshTokenRepository
{
    public async Task<int> CreateAsync(RefreshToken token)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            INSERT INTO dbo.RefreshTokens (UserID, TokenHash, ExpiresAt)
            OUTPUT INSERTED.RefreshTokenID
            VALUES (@UserID, @TokenHash, @ExpiresAt);
            """;
        return await connection.QuerySingleAsync<int>(sql, token);
    }

    public async Task<RefreshToken?> GetByHashAsync(string tokenHash)
    {
        using var connection = connectionFactory.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<RefreshToken>(
            "SELECT * FROM dbo.RefreshTokens WHERE TokenHash = @TokenHash", new { TokenHash = tokenHash });
    }

    public async Task RevokeAsync(int refreshTokenId, string? replacedByTokenHash)
    {
        using var connection = connectionFactory.CreateConnection();
        await connection.ExecuteAsync(
            "UPDATE dbo.RefreshTokens SET RevokedAt = SYSUTCDATETIME(), ReplacedByTokenHash = @ReplacedByTokenHash WHERE RefreshTokenID = @RefreshTokenID",
            new { RefreshTokenID = refreshTokenId, ReplacedByTokenHash = replacedByTokenHash });
    }

    public async Task RevokeAllActiveForUserAsync(int userId)
    {
        using var connection = connectionFactory.CreateConnection();
        await connection.ExecuteAsync(
            "UPDATE dbo.RefreshTokens SET RevokedAt = SYSUTCDATETIME() WHERE UserID = @UserID AND RevokedAt IS NULL",
            new { UserID = userId });
    }
}
