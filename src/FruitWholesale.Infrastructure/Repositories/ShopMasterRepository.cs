using Dapper;
using FruitWholesale.Application.Common.Interfaces;
using FruitWholesale.Domain.Entities;
using FruitWholesale.Domain.Enums;
using FruitWholesale.Shared.Pagination;

namespace FruitWholesale.Infrastructure.Repositories;

public class ShopMasterRepository(IDbConnectionFactory connectionFactory, ILedgerService ledgerService) : IShopMasterRepository
{
    public async Task<ShopMaster?> GetByIdAsync(int shopId)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            SELECT s.*, r.RouteName, ls.SupplierName AS LinkedSupplierName FROM ShopMaster s
            LEFT JOIN RouteMaster r ON r.RouteID = s.RouteID
            LEFT JOIN SupplierMaster ls ON ls.SupplierID = s.LinkedSupplierID
            WHERE s.ShopID = @ShopID;
            """;
        return await connection.QueryFirstOrDefaultAsync<ShopMaster>(sql, new { ShopID = shopId });
    }

    public async Task<IReadOnlyList<ShopMaster>> GetAllActiveAsync()
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            SELECT s.*, r.RouteName, ls.SupplierName AS LinkedSupplierName FROM ShopMaster s
            LEFT JOIN RouteMaster r ON r.RouteID = s.RouteID
            LEFT JOIN SupplierMaster ls ON ls.SupplierID = s.LinkedSupplierID
            WHERE s.IsActive = TRUE
            ORDER BY s.ShopName;
            """;
        var result = await connection.QueryAsync<ShopMaster>(sql);
        return result.ToList();
    }

    public async Task<PaginatedList<ShopMaster>> GetPagedAsync(PaginationRequest request, int? routeId = null)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            SELECT COUNT(*) FROM ShopMaster s
            WHERE (@SearchTerm::text IS NULL OR s.ShopName ILIKE @SearchPattern OR s.OwnerName ILIKE @SearchPattern OR s.Phone ILIKE @SearchPattern)
                AND (@RouteID::int IS NULL OR s.RouteID = @RouteID);

            SELECT s.*, r.RouteName, ls.SupplierName AS LinkedSupplierName FROM ShopMaster s
            LEFT JOIN RouteMaster r ON r.RouteID = s.RouteID
            LEFT JOIN SupplierMaster ls ON ls.SupplierID = s.LinkedSupplierID
            WHERE (@SearchTerm::text IS NULL OR s.ShopName ILIKE @SearchPattern OR s.OwnerName ILIKE @SearchPattern OR s.Phone ILIKE @SearchPattern)
                AND (@RouteID::int IS NULL OR s.RouteID = @RouteID)
            ORDER BY
                CASE WHEN @SortBy = 'shopName' AND NOT @SortDescending THEN s.ShopName END ASC,
                CASE WHEN @SortBy = 'shopName' AND @SortDescending THEN s.ShopName END DESC,
                CASE WHEN @SortBy IS NULL OR @SortBy <> 'shopName' THEN s.ShopName END ASC
            OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;
            """;
        using var multi = await connection.QueryMultipleAsync(sql, new
        {
            SearchTerm = request.SearchTerm,
            SearchPattern = $"%{request.SearchTerm}%",
            RouteID = routeId,
            request.SortBy,
            request.SortDescending,
            request.Offset,
            request.PageSize
        });
        var total = await multi.ReadSingleAsync<int>();
        var items = (await multi.ReadAsync<ShopMaster>()).ToList();
        return new PaginatedList<ShopMaster>(items, total, request.PageNumber, request.PageSize);
    }

    public async Task<int> CreateAsync(ShopMaster shop)
    {
        using var connection = connectionFactory.CreateConnection();
        connection.Open();
        using var transaction = connection.BeginTransaction();
        try
        {
            const string insertSql = """
                INSERT INTO ShopMaster (ShopName, OwnerName, Phone, Address, OpeningBalance, CreditLimit, RouteID, LinkedSupplierID, IsActive)
                VALUES (@ShopName, @OwnerName, @Phone, @Address, @OpeningBalance, @CreditLimit, @RouteID, @LinkedSupplierID, @IsActive)
                RETURNING ShopID;
                """;
            var shopId = await connection.QuerySingleAsync<int>(insertSql, shop, transaction);

            if (shop.OpeningBalance != 0)
            {
                await ledgerService.AddShopLedgerEntryAsync(connection, transaction, shopId, DateTime.UtcNow.Date,
                    LedgerTransactionTypes.OpeningBalance, null, shop.OpeningBalance, 0, "Opening balance");
            }

            transaction.Commit();
            return shopId;
        }
        catch
        {
            transaction.Rollback();
            throw;
        }
    }

    public async Task UpdateAsync(ShopMaster shop)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            UPDATE ShopMaster
            SET ShopName = @ShopName, OwnerName = @OwnerName, Phone = @Phone, Address = @Address,
                CreditLimit = @CreditLimit, RouteID = @RouteID, LinkedSupplierID = @LinkedSupplierID, UpdatedAt = (now() AT TIME ZONE 'utc')
            WHERE ShopID = @ShopID;
            """;
        await connection.ExecuteAsync(sql, shop);
    }

    public async Task SetActiveAsync(int shopId, bool isActive)
    {
        using var connection = connectionFactory.CreateConnection();
        await connection.ExecuteAsync(
            "UPDATE ShopMaster SET IsActive = @IsActive, UpdatedAt = (now() AT TIME ZONE 'utc') WHERE ShopID = @ShopID",
            new { ShopID = shopId, IsActive = isActive });
    }
}
