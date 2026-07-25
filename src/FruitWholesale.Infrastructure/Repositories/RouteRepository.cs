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
            "SELECT * FROM dbo.RouteMaster WHERE RouteID = @RouteID", new { RouteID = routeId });
    }

    public async Task<IReadOnlyList<RouteMaster>> GetAllActiveAsync()
    {
        using var connection = connectionFactory.CreateConnection();
        var result = await connection.QueryAsync<RouteMaster>(
            "SELECT * FROM dbo.RouteMaster WHERE IsActive = 1 ORDER BY RouteName");
        return result.ToList();
    }

    public async Task<PaginatedList<RouteMaster>> GetPagedAsync(PaginationRequest request)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            SELECT COUNT(*) FROM dbo.RouteMaster WHERE (@SearchTerm IS NULL OR RouteName LIKE @SearchPattern);

            SELECT * FROM dbo.RouteMaster
            WHERE (@SearchTerm IS NULL OR RouteName LIKE @SearchPattern)
            ORDER BY RouteName ASC
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
        var items = (await multi.ReadAsync<RouteMaster>()).ToList();
        return new PaginatedList<RouteMaster>(items, total, request.PageNumber, request.PageSize);
    }

    public async Task<int> CreateAsync(RouteMaster route)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            INSERT INTO dbo.RouteMaster (RouteName, Description, IsActive)
            OUTPUT INSERTED.RouteID
            VALUES (@RouteName, @Description, @IsActive);
            """;
        return await connection.QuerySingleAsync<int>(sql, route);
    }

    public async Task UpdateAsync(RouteMaster route)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            UPDATE dbo.RouteMaster
            SET RouteName = @RouteName, Description = @Description, UpdatedAt = SYSUTCDATETIME()
            WHERE RouteID = @RouteID;
            """;
        await connection.ExecuteAsync(sql, route);
    }

    public async Task SetActiveAsync(int routeId, bool isActive)
    {
        using var connection = connectionFactory.CreateConnection();
        await connection.ExecuteAsync(
            "UPDATE dbo.RouteMaster SET IsActive = @IsActive, UpdatedAt = SYSUTCDATETIME() WHERE RouteID = @RouteID",
            new { RouteID = routeId, IsActive = isActive });
    }

    public async Task<bool> NameExistsAsync(string routeName, int? excludeRouteId = null)
    {
        using var connection = connectionFactory.CreateConnection();
        return await connection.ExecuteScalarAsync<bool>(
            "SELECT CASE WHEN EXISTS (SELECT 1 FROM dbo.RouteMaster WHERE RouteName = @RouteName AND (@ExcludeRouteId IS NULL OR RouteID <> @ExcludeRouteId)) THEN 1 ELSE 0 END",
            new { RouteName = routeName, ExcludeRouteId = excludeRouteId });
    }

    public async Task<int> GetShopCountAsync(int routeId)
    {
        using var connection = connectionFactory.CreateConnection();
        return await connection.ExecuteScalarAsync<int>(
            "SELECT COUNT(*) FROM dbo.ShopMaster WHERE RouteID = @RouteID", new { RouteID = routeId });
    }
}
