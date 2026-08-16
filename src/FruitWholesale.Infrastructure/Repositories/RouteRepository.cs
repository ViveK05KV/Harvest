using Dapper;
using FruitWholesale.Application.Common.Interfaces;
using FruitWholesale.Domain.Entities;
using FruitWholesale.Shared.Pagination;

namespace FruitWholesale.Infrastructure.Repositories;

public class RouteRepository(IDbConnectionFactory connectionFactory) : IRouteRepository
{
    public async Task<RouteMaster?> GetByIdAsync(int routeId)
    {
        using var connection = connectionFactory.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<RouteMaster>(
            "SELECT * FROM RouteMaster WHERE RouteID = @RouteID", new { RouteID = routeId });
    }

    public async Task<IReadOnlyList<RouteMaster>> GetAllActiveAsync()
    {
        using var connection = connectionFactory.CreateConnection();
        var result = await connection.QueryAsync<RouteMaster>(
            "SELECT * FROM RouteMaster WHERE IsActive = TRUE ORDER BY RouteName");
        return result.ToList();
    }

    public async Task<PaginatedList<RouteMaster>> GetPagedAsync(PaginationRequest request)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            SELECT COUNT(*) FROM RouteMaster WHERE (@SearchTerm::text IS NULL OR RouteName ILIKE @SearchPattern);

            SELECT * FROM RouteMaster
            WHERE (@SearchTerm::text IS NULL OR RouteName ILIKE @SearchPattern)
            ORDER BY
                CASE WHEN @SortBy = 'routeName' AND NOT @SortDescending THEN RouteName END ASC,
                CASE WHEN @SortBy = 'routeName' AND @SortDescending THEN RouteName END DESC,
                CASE WHEN @SortBy IS NULL OR @SortBy <> 'routeName' THEN RouteName END ASC
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
        var items = (await multi.ReadAsync<RouteMaster>()).ToList();
        return new PaginatedList<RouteMaster>(items, total, request.PageNumber, request.PageSize);
    }

    public async Task<int> CreateAsync(RouteMaster route)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            INSERT INTO RouteMaster (RouteName, Description, IsActive)
            VALUES (@RouteName, @Description, @IsActive)
            RETURNING RouteID;
            """;
        return await connection.QuerySingleAsync<int>(sql, route);
    }

    public async Task UpdateAsync(RouteMaster route)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            UPDATE RouteMaster
            SET RouteName = @RouteName, Description = @Description, UpdatedAt = (now() AT TIME ZONE 'utc')
            WHERE RouteID = @RouteID;
            """;
        await connection.ExecuteAsync(sql, route);
    }

    public async Task SetActiveAsync(int routeId, bool isActive)
    {
        using var connection = connectionFactory.CreateConnection();
        await connection.ExecuteAsync(
            "UPDATE RouteMaster SET IsActive = @IsActive, UpdatedAt = (now() AT TIME ZONE 'utc') WHERE RouteID = @RouteID",
            new { RouteID = routeId, IsActive = isActive });
    }

    public async Task<bool> NameExistsAsync(string routeName, int? excludeRouteId = null)
    {
        using var connection = connectionFactory.CreateConnection();
        return await connection.ExecuteScalarAsync<bool>(
            "SELECT EXISTS (SELECT 1 FROM RouteMaster WHERE RouteName = @RouteName AND (@ExcludeRouteId::int IS NULL OR RouteID <> @ExcludeRouteId))",
            new { RouteName = routeName, ExcludeRouteId = excludeRouteId });
    }

    public async Task<int> GetShopCountAsync(int routeId)
    {
        using var connection = connectionFactory.CreateConnection();
        return await connection.ExecuteScalarAsync<int>(
            "SELECT COUNT(*) FROM ShopMaster WHERE RouteID = @RouteID", new { RouteID = routeId });
    }

    public async Task<Dictionary<int, int>> GetShopCountBatchAsync(IEnumerable<int> routeIds)
    {
        var ids = routeIds.Distinct().ToList();
        if (ids.Count == 0) return [];

        using var connection = connectionFactory.CreateConnection();
        var rows = await connection.QueryAsync<(int RouteID, int ShopCount)>(
            "SELECT RouteID, COUNT(*) AS ShopCount FROM ShopMaster WHERE RouteID = ANY(@RouteIDs) GROUP BY RouteID",
            new { RouteIDs = ids });
        return rows.ToDictionary(r => r.RouteID, r => r.ShopCount);
    }
}
