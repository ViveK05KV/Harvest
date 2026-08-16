using System.Data;
using Dapper;
using FruitWholesale.Application.Common.Interfaces;
using FruitWholesale.Application.DTOs.Collection;
using FruitWholesale.Domain.Entities;
using FruitWholesale.Domain.Enums;
using FruitWholesale.Shared.Exceptions;
using FruitWholesale.Shared.Pagination;

namespace FruitWholesale.Infrastructure.Repositories;

public class CollectionRepository(IDbConnectionFactory connectionFactory, ILedgerService ledgerService) : ICollectionRepository
{
    public async Task<Collection?> GetByIdAsync(int collectionId)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            SELECT c.*, sh.ShopName FROM Collections c
            INNER JOIN ShopMaster sh ON sh.ShopID = c.ShopID
            WHERE c.CollectionID = @CollectionID;
            """;
        return await connection.QueryFirstOrDefaultAsync<Collection>(sql, new { CollectionID = collectionId });
    }

    public async Task<PaginatedList<Collection>> GetPagedAsync(PaginationRequest request, int? shopId, DateTime? fromDate, DateTime? toDate)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            SELECT COUNT(*) FROM Collections c
            INNER JOIN ShopMaster sh ON sh.ShopID = c.ShopID
            WHERE (@ShopID::int IS NULL OR c.ShopID = @ShopID)
              AND (@FromDate::date IS NULL OR c.CollectionDate >= @FromDate)
              AND (@ToDate::date IS NULL OR c.CollectionDate <= @ToDate)
              AND (@SearchTerm::text IS NULL OR sh.ShopName ILIKE @SearchPattern OR c.ReferenceNumber ILIKE @SearchPattern);

            SELECT c.*, sh.ShopName FROM Collections c
            INNER JOIN ShopMaster sh ON sh.ShopID = c.ShopID
            WHERE (@ShopID::int IS NULL OR c.ShopID = @ShopID)
              AND (@FromDate::date IS NULL OR c.CollectionDate >= @FromDate)
              AND (@ToDate::date IS NULL OR c.CollectionDate <= @ToDate)
              AND (@SearchTerm::text IS NULL OR sh.ShopName ILIKE @SearchPattern OR c.ReferenceNumber ILIKE @SearchPattern)
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
                INSERT INTO Collections (CollectionDate, ShopID, AmountReceived, DiscountAmount, PaymentMode, ReferenceNumber, Remarks, CreatedBy, CollectionType, TemporaryStatus)
                VALUES (@CollectionDate, @ShopID, @AmountReceived, @DiscountAmount, @PaymentMode, @ReferenceNumber, @Remarks, @CreatedBy, @CollectionType, @TemporaryStatus)
                RETURNING CollectionID;
                """;
            var collectionId = await connection.QuerySingleAsync<int>(insertSql, collection, transaction);

            var isTemporary = collection.CollectionType == CollectionTypes.Temporary;
            if (!isTemporary)
            {
                await ledgerService.AddShopLedgerEntryAsync(connection, transaction, collection.ShopID, collection.CollectionDate,
                    LedgerTransactionTypes.Collection, collectionId, 0, collection.AmountReceived + collection.DiscountAmount,
                    CollectionNarration(collection));
                await ledgerService.RecalculateShopLedgerAsync(connection, transaction, collection.ShopID);
            }

            var cashNarration = isTemporary
                ? $"Temporary collection from {await ShopNameAsync(connection, transaction, collection.ShopID)}"
                : $"Collection from {await ShopNameAsync(connection, transaction, collection.ShopID)}";
            await ledgerService.AddCashLedgerEntryAsync(connection, transaction, collection.CollectionDate,
                LedgerTransactionTypes.Collection, ReferenceTables.Collections, collectionId, collection.PaymentMode,
                collection.AmountReceived, 0, cashNarration);
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
            var existing = await connection.QuerySingleOrDefaultAsync<Collection>(
                "SELECT CollectionID, ShopID, CollectionType, TemporaryStatus, SettlementID FROM Collections WHERE CollectionID = @CollectionID",
                new { collection.CollectionID }, transaction);
            if (existing is null)
            {
                throw new NotFoundException(nameof(Collection), collection.CollectionID);
            }

            if (existing.TemporaryStatus == TemporaryCollectionStatuses.Settled)
            {
                throw new BusinessRuleException("Settled temporary collections cannot be edited.");
            }

            var oldShopId = existing.ShopID;
            var oldCollectionType = existing.CollectionType;
            var isTemporary = collection.CollectionType == CollectionTypes.Temporary;
            var hadShopLedger = oldCollectionType != CollectionTypes.Temporary;
            var shouldHaveShopLedger = !isTemporary;

            const string updateSql = """
                UPDATE Collections
                SET CollectionDate = @CollectionDate, ShopID = @ShopID, AmountReceived = @AmountReceived,
                    DiscountAmount = @DiscountAmount, PaymentMode = @PaymentMode, ReferenceNumber = @ReferenceNumber,
                    Remarks = @Remarks, CollectionType = @CollectionType, TemporaryStatus = @TemporaryStatus,
                    SettlementID = @SettlementID, UpdatedAt = (now() AT TIME ZONE 'utc')
                WHERE CollectionID = @CollectionID;
                """;
            await connection.ExecuteAsync(updateSql, collection, transaction);

            if (hadShopLedger)
            {
                await ledgerService.RemoveShopLedgerEntriesForReferenceAsync(connection, transaction, LedgerTransactionTypes.Collection, collection.CollectionID);
            }

            if (shouldHaveShopLedger)
            {
                await ledgerService.AddShopLedgerEntryAsync(connection, transaction, collection.ShopID, collection.CollectionDate,
                    LedgerTransactionTypes.Collection, collection.CollectionID, 0, collection.AmountReceived + collection.DiscountAmount,
                    CollectionNarration(collection));
            }

            if (hadShopLedger || shouldHaveShopLedger)
            {
                await ledgerService.RecalculateShopLedgerAsync(connection, transaction, collection.ShopID);
            }
            if (hadShopLedger && oldShopId != collection.ShopID)
            {
                await ledgerService.RecalculateShopLedgerAsync(connection, transaction, oldShopId);
            }

            await ledgerService.RemoveCashLedgerEntriesForReferenceAsync(connection, transaction, ReferenceTables.Collections, collection.CollectionID);
            var cashNarration = isTemporary
                ? $"Temporary collection from {await ShopNameAsync(connection, transaction, collection.ShopID)}"
                : $"Collection from {await ShopNameAsync(connection, transaction, collection.ShopID)}";
            await ledgerService.AddCashLedgerEntryAsync(connection, transaction, collection.CollectionDate,
                LedgerTransactionTypes.Collection, ReferenceTables.Collections, collection.CollectionID, collection.PaymentMode,
                collection.AmountReceived, 0, cashNarration);
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
            var existing = await connection.QuerySingleOrDefaultAsync<Collection>(
                "SELECT CollectionID, ShopID, CollectionType, TemporaryStatus FROM Collections WHERE CollectionID = @CollectionID",
                new { CollectionID = collectionId }, transaction);
            if (existing is null)
            {
                throw new NotFoundException(nameof(Collection), collectionId);
            }

            if (existing.TemporaryStatus == TemporaryCollectionStatuses.Settled)
            {
                throw new BusinessRuleException("Settled temporary collections cannot be deleted.");
            }

            var shopId = existing.ShopID;
            if (existing.CollectionType != CollectionTypes.Temporary)
            {
                await ledgerService.RemoveShopLedgerEntriesForReferenceAsync(connection, transaction, LedgerTransactionTypes.Collection, collectionId);
            }

            await ledgerService.RemoveCashLedgerEntriesForReferenceAsync(connection, transaction, ReferenceTables.Collections, collectionId);
            await connection.ExecuteAsync("DELETE FROM Collections WHERE CollectionID = @CollectionID", new { CollectionID = collectionId }, transaction);

            if (existing.CollectionType != CollectionTypes.Temporary)
            {
                await ledgerService.RecalculateShopLedgerAsync(connection, transaction, shopId);
            }
            await ledgerService.RecalculateCashLedgerAsync(connection, transaction);

            transaction.Commit();
        }
        catch
        {
            transaction.Rollback();
            throw;
        }
    }

    public async Task<CollectionSettlementPreviewDto> GetPendingSettlementPreviewAsync(int shopId)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            SELECT sh.ShopID, sh.ShopName, COUNT(c.CollectionID) AS PendingCount, COALESCE(SUM(c.AmountReceived), 0) AS PendingTotal
            FROM ShopMaster sh
            LEFT JOIN Collections c ON c.ShopID = sh.ShopID
                AND c.CollectionType = 'Temporary'
                AND c.TemporaryStatus = 'Pending'
            WHERE sh.ShopID = @ShopID
            GROUP BY sh.ShopID, sh.ShopName
            LIMIT 1;
            """;
        return await connection.QueryFirstOrDefaultAsync<CollectionSettlementPreviewDto>(sql, new { ShopID = shopId })
            ?? new CollectionSettlementPreviewDto { ShopID = shopId, PendingCount = 0, PendingTotal = 0m };
    }

    public async Task<CollectionSettlementResultDto> SettlePendingAsync(int shopId, DateTime settlementDate, int? createdBy)
    {
        using var connection = connectionFactory.CreateConnection();
        connection.Open();
        using var transaction = connection.BeginTransaction();
        try
        {
            var pendingRows = (await connection.QueryAsync<Collection>("""
                SELECT CollectionID, ShopID, AmountReceived, CollectionDate, CollectionType, TemporaryStatus
                FROM Collections
                WHERE ShopID = @ShopID
                  AND CollectionType = 'Temporary'
                  AND TemporaryStatus = 'Pending'
                ORDER BY CollectionDate ASC, CollectionID ASC;
                """, new { ShopID = shopId }, transaction)).ToList();

            if (pendingRows.Count == 0)
            {
                transaction.Commit();
                return new CollectionSettlementResultDto { ShopID = shopId, SettlementDate = settlementDate, TotalAmount = 0m, PendingCount = 0 };
            }

            var totalAmount = pendingRows.Sum(x => x.AmountReceived);
            var settlementId = await connection.ExecuteScalarAsync<int>("""
                INSERT INTO TemporaryCollectionSettlements (ShopID, SettlementDate, TotalAmount, CreatedBy)
                VALUES (@ShopID, @SettlementDate, @TotalAmount, @CreatedBy)
                RETURNING TemporaryCollectionSettlementID;
                """, new { ShopID = shopId, SettlementDate = settlementDate, TotalAmount = totalAmount, CreatedBy = createdBy }, transaction);

            await ledgerService.AddShopLedgerEntryAsync(connection, transaction, shopId, settlementDate,
                LedgerTransactionTypes.TemporaryCollectionSettlement, settlementId, 0, totalAmount,
                $"Temporary collection settlement for {await ShopNameAsync(connection, transaction, shopId)}");
            await ledgerService.RecalculateShopLedgerAsync(connection, transaction, shopId);

            foreach (var row in pendingRows)
            {
                await connection.ExecuteAsync("""
                    UPDATE Collections
                    SET TemporaryStatus = 'Settled', SettlementID = @SettlementID
                    WHERE CollectionID = @CollectionID;
                    """, new { CollectionID = row.CollectionID, SettlementID = settlementId }, transaction);
            }

            transaction.Commit();
            return new CollectionSettlementResultDto { SettlementID = settlementId, ShopID = shopId, SettlementDate = settlementDate, TotalAmount = totalAmount, PendingCount = pendingRows.Count };
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

    private static async Task<string> ShopNameAsync(IDbConnection connection, IDbTransaction transaction, int shopId) =>
        await connection.QueryFirstOrDefaultAsync<string>(
            "SELECT ShopName FROM ShopMaster WHERE ShopID = @ShopID", new { ShopID = shopId }, transaction)
        ?? "Unknown Shop";
}
