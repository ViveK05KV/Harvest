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
            "SELECT * FROM FruitMaster WHERE FruitID = @FruitID", new { FruitID = fruitId });
    }

    public async Task<IReadOnlyList<FruitMaster>> GetAllActiveAsync()
    {
        using var connection = connectionFactory.CreateConnection();
        var result = await connection.QueryAsync<FruitMaster>(
            "SELECT * FROM FruitMaster WHERE IsActive = TRUE ORDER BY FruitName");
        return result.ToList();
    }

    public async Task<PaginatedList<FruitMaster>> GetPagedAsync(PaginationRequest request)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            SELECT COUNT(*) FROM FruitMaster WHERE (@SearchTerm::text IS NULL OR FruitName ILIKE @SearchPattern);

            SELECT * FROM FruitMaster
            WHERE (@SearchTerm::text IS NULL OR FruitName ILIKE @SearchPattern)
            ORDER BY
                CASE WHEN @SortBy = 'fruitName' AND NOT @SortDescending THEN FruitName END ASC,
                CASE WHEN @SortBy = 'fruitName' AND @SortDescending THEN FruitName END DESC,
                CASE WHEN @SortBy = 'unit' AND NOT @SortDescending THEN Unit END ASC,
                CASE WHEN @SortBy = 'unit' AND @SortDescending THEN Unit END DESC,
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
            INSERT INTO FruitMaster (FruitName, Unit, TracksByBox, BoxWeightKg, IsActive)
            VALUES (@FruitName, @Unit, @TracksByBox, @BoxWeightKg, @IsActive)
            RETURNING FruitID;
            """;
        return await connection.QuerySingleAsync<int>(sql, fruit);
    }

    public async Task UpdateAsync(FruitMaster fruit)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            UPDATE FruitMaster
            SET FruitName = @FruitName, Unit = @Unit, TracksByBox = @TracksByBox, BoxWeightKg = @BoxWeightKg, UpdatedAt = (now() AT TIME ZONE 'utc')
            WHERE FruitID = @FruitID;
            """;
        await connection.ExecuteAsync(sql, fruit);
    }

    public async Task SetActiveAsync(int fruitId, bool isActive)
    {
        using var connection = connectionFactory.CreateConnection();
        await connection.ExecuteAsync(
            "UPDATE FruitMaster SET IsActive = @IsActive, UpdatedAt = (now() AT TIME ZONE 'utc') WHERE FruitID = @FruitID",
            new { FruitID = fruitId, IsActive = isActive });
    }

    public async Task<bool> NameExistsAsync(string fruitName, int? excludeFruitId = null)
    {
        using var connection = connectionFactory.CreateConnection();
        return await connection.ExecuteScalarAsync<bool>(
            "SELECT EXISTS (SELECT 1 FROM FruitMaster WHERE FruitName = @FruitName AND (@ExcludeFruitId::int IS NULL OR FruitID <> @ExcludeFruitId))",
            new { FruitName = fruitName, ExcludeFruitId = excludeFruitId });
    }
}
