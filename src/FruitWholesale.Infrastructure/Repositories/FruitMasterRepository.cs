using Dapper;
using FruitWholesale.Application.Common.Interfaces;
using FruitWholesale.Domain.Entities;
using FruitWholesale.Shared.Pagination;

namespace FruitWholesale.Infrastructure.Repositories;

public class FruitMasterRepository(IDbConnectionFactory connectionFactory) : IFruitMasterRepository
{
    public async Task<FruitMaster?> GetByIdAsync(int fruitId)
    {
        using var connection = connectionFactory.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<FruitMaster>(
            "SELECT * FROM dbo.FruitMaster WHERE FruitID = @FruitID", new { FruitID = fruitId });
    }

    public async Task<IReadOnlyList<FruitMaster>> GetAllActiveAsync()
    {
        using var connection = connectionFactory.CreateConnection();
        var result = await connection.QueryAsync<FruitMaster>(
            "SELECT * FROM dbo.FruitMaster WHERE IsActive = 1 ORDER BY FruitName");
        return result.ToList();
    }

    public async Task<PaginatedList<FruitMaster>> GetPagedAsync(PaginationRequest request)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            SELECT COUNT(*) FROM dbo.FruitMaster WHERE (@SearchTerm IS NULL OR FruitName LIKE @SearchPattern);

            SELECT * FROM dbo.FruitMaster
            WHERE (@SearchTerm IS NULL OR FruitName LIKE @SearchPattern)
            ORDER BY
                CASE WHEN @SortBy = 'fruitName' AND @SortDescending = 0 THEN FruitName END ASC,
                CASE WHEN @SortBy = 'fruitName' AND @SortDescending = 1 THEN FruitName END DESC,
                CASE WHEN @SortBy = 'unit' AND @SortDescending = 0 THEN Unit END ASC,
                CASE WHEN @SortBy = 'unit' AND @SortDescending = 1 THEN Unit END DESC,
                CASE WHEN @SortBy IS NULL OR (@SortBy <> 'fruitName' AND @SortBy <> 'unit') THEN FruitName END ASC
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
        var items = (await multi.ReadAsync<FruitMaster>()).ToList();
        return new PaginatedList<FruitMaster>(items, total, request.PageNumber, request.PageSize);
    }

    public async Task<int> CreateAsync(FruitMaster fruit)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            INSERT INTO dbo.FruitMaster (FruitName, Unit, TracksByBox, BoxWeightKg, IsActive)
            OUTPUT INSERTED.FruitID
            VALUES (@FruitName, @Unit, @TracksByBox, @BoxWeightKg, @IsActive);
            """;
        return await connection.QuerySingleAsync<int>(sql, fruit);
    }

    public async Task UpdateAsync(FruitMaster fruit)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            UPDATE dbo.FruitMaster
            SET FruitName = @FruitName, Unit = @Unit, TracksByBox = @TracksByBox, BoxWeightKg = @BoxWeightKg, UpdatedAt = SYSUTCDATETIME()
            WHERE FruitID = @FruitID;
            """;
        await connection.ExecuteAsync(sql, fruit);
    }

    public async Task SetActiveAsync(int fruitId, bool isActive)
    {
        using var connection = connectionFactory.CreateConnection();
        await connection.ExecuteAsync(
            "UPDATE dbo.FruitMaster SET IsActive = @IsActive, UpdatedAt = SYSUTCDATETIME() WHERE FruitID = @FruitID",
            new { FruitID = fruitId, IsActive = isActive });
    }

    public async Task<bool> NameExistsAsync(string fruitName, int? excludeFruitId = null)
    {
        using var connection = connectionFactory.CreateConnection();
        return await connection.ExecuteScalarAsync<bool>(
            "SELECT CASE WHEN EXISTS (SELECT 1 FROM dbo.FruitMaster WHERE FruitName = @FruitName AND (@ExcludeFruitId IS NULL OR FruitID <> @ExcludeFruitId)) THEN 1 ELSE 0 END",
            new { FruitName = fruitName, ExcludeFruitId = excludeFruitId });
    }
}
