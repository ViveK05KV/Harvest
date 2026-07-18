using Dapper;
using FruitWholesale.Application.Common.Interfaces;
using FruitWholesale.Domain.Entities;
using FruitWholesale.Domain.Enums;
using FruitWholesale.Shared.Pagination;

namespace FruitWholesale.Infrastructure.Repositories;

public class CollectionRepository(IDbConnectionFactory connectionFactory, ILedgerService ledgerService) : ICollectionRepository
{
    public async Task<Collection?> GetByIdAsync(int collectionId)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            SELECT c.*, sh.ShopName FROM dbo.Collections c
            INNER JOIN dbo.ShopMaster sh ON sh.ShopID = c.ShopID
            WHERE c.CollectionID = @CollectionID;
            """;
        return await connection.QueryFirstOrDefaultAsync<Collection>(sql, new { CollectionID = collectionId });
    }

    public async Task<PaginatedList<Collection>> GetPagedAsync(PaginationRequest request, int? shopId, DateTime? fromDate, DateTime? toDate)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            SELECT COUNT(*) FROM dbo.Collections c
            INNER JOIN dbo.ShopMaster sh ON sh.ShopID = c.ShopID
            WHERE (@ShopID IS NULL OR c.ShopID = @ShopID)
              AND (@FromDate IS NULL OR c.CollectionDate >= @FromDate)
              AND (@ToDate IS NULL OR c.CollectionDate <= @ToDate)
              AND (@SearchTerm IS NULL OR sh.ShopName LIKE @SearchPattern OR c.ReferenceNumber LIKE @SearchPattern);

            SELECT c.*, sh.ShopName FROM dbo.Collections c
            INNER JOIN dbo.ShopMaster sh ON sh.ShopID = c.ShopID
            WHERE (@ShopID IS NULL OR c.ShopID = @ShopID)
              AND (@FromDate IS NULL OR c.CollectionDate >= @FromDate)
              AND (@ToDate IS NULL OR c.CollectionDate <= @ToDate)
              AND (@SearchTerm IS NULL OR sh.ShopName LIKE @SearchPattern OR c.ReferenceNumber LIKE @SearchPattern)
            ORDER BY c.CollectionDate DESC, c.CollectionID DESC
            OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;
            """;
        using var multi = await connection.QueryMultipleAsync(sql, new
        {
            ShopID = shopId,
            FromDate = fromDate,
            ToDate = toDate,
            SearchTerm = request.SearchTerm,
            SearchPattern = $"%{request.SearchTerm}%",
            request.Offset,
            request.PageSize
        });
        var total = await multi.ReadSingleAsync<int>();
        var items = (await multi.ReadAsync<Collection>()).ToList();
        return new PaginatedList<Collection>(items, total, request.PageNumber, request.PageSize);
    }

    public async Task<int> CreateAsync(Collection collection)
    {
        using var connection = connectionFactory.CreateConnection();
        connection.Open();
        using var transaction = connection.BeginTransaction();
        try
        {
            const string insertSql = """
                INSERT INTO dbo.Collections (CollectionDate, ShopID, AmountReceived, DiscountAmount, PaymentMode, ReferenceNumber, Remarks, CreatedBy)
                OUTPUT INSERTED.CollectionID
                VALUES (@CollectionDate, @ShopID, @AmountReceived, @DiscountAmount, @PaymentMode, @ReferenceNumber, @Remarks, @CreatedBy);
                """;
            var collectionId = await connection.QuerySingleAsync<int>(insertSql, collection, transaction);

            await ledgerService.AddShopLedgerEntryAsync(connection, transaction, collection.ShopID, collection.CollectionDate,
                LedgerTransactionTypes.Collection, collectionId, 0, collection.AmountReceived + collection.DiscountAmount,
                CollectionNarration(collection));
            await ledgerService.RecalculateShopLedgerAsync(connection, transaction, collection.ShopID);

            await ledgerService.AddCashLedgerEntryAsync(connection, transaction, collection.CollectionDate,
                LedgerTransactionTypes.Collection, ReferenceTables.Collections, collectionId, collection.PaymentMode,
                collection.AmountReceived, 0, $"Collection from shop (ID {collection.ShopID})");
            await ledgerService.RecalculateCashLedgerAsync(connection, transaction);

            transaction.Commit();
            return collectionId;
        }
        catch
        {
            transaction.Rollback();
            throw;
        }
    }

    public async Task UpdateAsync(Collection collection)
    {
        using var connection = connectionFactory.CreateConnection();
        connection.Open();
        using var transaction = connection.BeginTransaction();
        try
        {
            var oldShopId = await connection.ExecuteScalarAsync<int>(
                "SELECT ShopID FROM dbo.Collections WHERE CollectionID = @CollectionID", new { collection.CollectionID }, transaction);

            const string updateSql = """
                UPDATE dbo.Collections
                SET CollectionDate = @CollectionDate, ShopID = @ShopID, AmountReceived = @AmountReceived,
                    DiscountAmount = @DiscountAmount, PaymentMode = @PaymentMode, ReferenceNumber = @ReferenceNumber,
                    Remarks = @Remarks, UpdatedAt = SYSUTCDATETIME()
                WHERE CollectionID = @CollectionID;
                """;
            await connection.ExecuteAsync(updateSql, collection, transaction);

            await ledgerService.RemoveShopLedgerEntriesForReferenceAsync(connection, transaction, LedgerTransactionTypes.Collection, collection.CollectionID);
            await ledgerService.AddShopLedgerEntryAsync(connection, transaction, collection.ShopID, collection.CollectionDate,
                LedgerTransactionTypes.Collection, collection.CollectionID, 0, collection.AmountReceived + collection.DiscountAmount,
                CollectionNarration(collection));
            await ledgerService.RecalculateShopLedgerAsync(connection, transaction, collection.ShopID);
            if (oldShopId != collection.ShopID)
            {
                await ledgerService.RecalculateShopLedgerAsync(connection, transaction, oldShopId);
            }

            await ledgerService.RemoveCashLedgerEntriesForReferenceAsync(connection, transaction, ReferenceTables.Collections, collection.CollectionID);
            await ledgerService.AddCashLedgerEntryAsync(connection, transaction, collection.CollectionDate,
                LedgerTransactionTypes.Collection, ReferenceTables.Collections, collection.CollectionID, collection.PaymentMode,
                collection.AmountReceived, 0, $"Collection from shop (ID {collection.ShopID})");
            await ledgerService.RecalculateCashLedgerAsync(connection, transaction);

            transaction.Commit();
        }
        catch
        {
            transaction.Rollback();
            throw;
        }
    }

    public async Task DeleteAsync(int collectionId)
    {
        using var connection = connectionFactory.CreateConnection();
        connection.Open();
        using var transaction = connection.BeginTransaction();
        try
        {
            var shopId = await connection.ExecuteScalarAsync<int>(
                "SELECT ShopID FROM dbo.Collections WHERE CollectionID = @CollectionID", new { CollectionID = collectionId }, transaction);

            await ledgerService.RemoveShopLedgerEntriesForReferenceAsync(connection, transaction, LedgerTransactionTypes.Collection, collectionId);
            await ledgerService.RemoveCashLedgerEntriesForReferenceAsync(connection, transaction, ReferenceTables.Collections, collectionId);
            await connection.ExecuteAsync("DELETE FROM dbo.Collections WHERE CollectionID = @CollectionID", new { CollectionID = collectionId }, transaction);

            await ledgerService.RecalculateShopLedgerAsync(connection, transaction, shopId);
            await ledgerService.RecalculateCashLedgerAsync(connection, transaction);

            transaction.Commit();
        }
        catch
        {
            transaction.Rollback();
            throw;
        }
    }

    private static string CollectionNarration(Collection collection) =>
        collection.DiscountAmount > 0
            ? $"Collection received ({collection.PaymentMode}) + discount {collection.DiscountAmount:0.##}"
            : $"Collection received ({collection.PaymentMode})";
}
