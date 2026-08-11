using Dapper;
using FruitWholesale.Application.Common.Interfaces;
using FruitWholesale.Domain.Entities;
using FruitWholesale.Domain.Enums;
using FruitWholesale.Shared.Pagination;

namespace FruitWholesale.Infrastructure.Repositories;

public class SupplierMasterRepository(IDbConnectionFactory connectionFactory, ILedgerService ledgerService) : ISupplierMasterRepository
{
    // OUTER APPLY TOP 1 rather than a plain LEFT JOIN so a supplier can never
    // multiply into extra rows even if more than one shop were ever linked to it.
    private const string LinkedShopJoin = """
        OUTER APPLY (
            SELECT TOP 1 sh.ShopID, sh.ShopName
            FROM dbo.ShopMaster sh
            WHERE sh.LinkedSupplierID = s.SupplierID
        ) linkedShop
        """;

    public async Task<SupplierMaster?> GetByIdAsync(int supplierId)
    {
        using var connection = connectionFactory.CreateConnection();
        var sql = $"""
            SELECT s.*, linkedShop.ShopID AS LinkedShopID, linkedShop.ShopName AS LinkedShopName
            FROM dbo.SupplierMaster s
            {LinkedShopJoin}
            WHERE s.SupplierID = @SupplierID;
            """;
        return await connection.QueryFirstOrDefaultAsync<SupplierMaster>(sql, new { SupplierID = supplierId });
    }

    public async Task<IReadOnlyList<SupplierMaster>> GetAllActiveAsync()
    {
        using var connection = connectionFactory.CreateConnection();
        var sql = $"""
            SELECT s.*, linkedShop.ShopID AS LinkedShopID, linkedShop.ShopName AS LinkedShopName
            FROM dbo.SupplierMaster s
            {LinkedShopJoin}
            WHERE s.IsActive = 1
            ORDER BY s.SupplierName;
            """;
        var result = await connection.QueryAsync<SupplierMaster>(sql);
        return result.ToList();
    }

    public async Task<PaginatedList<SupplierMaster>> GetPagedAsync(PaginationRequest request)
    {
        using var connection = connectionFactory.CreateConnection();
        var sql = $"""
            SELECT COUNT(*) FROM dbo.SupplierMaster s
            WHERE (@SearchTerm IS NULL OR s.SupplierName LIKE @SearchPattern OR s.Phone LIKE @SearchPattern);

            SELECT s.*, linkedShop.ShopID AS LinkedShopID, linkedShop.ShopName AS LinkedShopName
            FROM dbo.SupplierMaster s
            {LinkedShopJoin}
            WHERE (@SearchTerm IS NULL OR s.SupplierName LIKE @SearchPattern OR s.Phone LIKE @SearchPattern)
            ORDER BY
                CASE WHEN @SortBy = 'supplierName' AND @SortDescending = 0 THEN s.SupplierName END ASC,
                CASE WHEN @SortBy = 'supplierName' AND @SortDescending = 1 THEN s.SupplierName END DESC,
                CASE WHEN @SortBy IS NULL OR @SortBy <> 'supplierName' THEN s.SupplierName END ASC
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
        var items = (await multi.ReadAsync<SupplierMaster>()).ToList();
        return new PaginatedList<SupplierMaster>(items, total, request.PageNumber, request.PageSize);
    }

    public async Task<int> CreateAsync(SupplierMaster supplier)
    {
        using var connection = connectionFactory.CreateConnection();
        connection.Open();
        using var transaction = connection.BeginTransaction();
        try
        {
            const string insertSql = """
                INSERT INTO dbo.SupplierMaster (SupplierName, Phone, Address, OpeningBalance, IsActive)
                OUTPUT INSERTED.SupplierID
                VALUES (@SupplierName, @Phone, @Address, @OpeningBalance, @IsActive);
                """;
            var supplierId = await connection.QuerySingleAsync<int>(insertSql, supplier, transaction);

            if (supplier.OpeningBalance != 0)
            {
                await ledgerService.AddSupplierLedgerEntryAsync(connection, transaction, supplierId, DateTime.UtcNow.Date,
                    LedgerTransactionTypes.OpeningBalance, null, supplier.OpeningBalance, 0, "Opening balance");
            }

            transaction.Commit();
            return supplierId;
        }
        catch
        {
            transaction.Rollback();
            throw;
        }
    }

    public async Task UpdateAsync(SupplierMaster supplier)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            UPDATE dbo.SupplierMaster
            SET SupplierName = @SupplierName, Phone = @Phone, Address = @Address, UpdatedAt = SYSUTCDATETIME()
            WHERE SupplierID = @SupplierID;
            """;
        await connection.ExecuteAsync(sql, supplier);
    }

    public async Task SetActiveAsync(int supplierId, bool isActive)
    {
        using var connection = connectionFactory.CreateConnection();
        await connection.ExecuteAsync(
            "UPDATE dbo.SupplierMaster SET IsActive = @IsActive, UpdatedAt = SYSUTCDATETIME() WHERE SupplierID = @SupplierID",
            new { SupplierID = supplierId, IsActive = isActive });
    }
}
