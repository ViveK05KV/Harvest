using Dapper;
using FruitWholesale.Application.Common.Interfaces;
using FruitWholesale.Application.DTOs.Supply;
using FruitWholesale.Domain.Entities;
using FruitWholesale.Domain.Enums;
using FruitWholesale.Shared.Pagination;

namespace FruitWholesale.Infrastructure.Repositories;

public class SupplyRepository(IDbConnectionFactory connectionFactory, ILedgerService ledgerService) : ISupplyRepository
{
    public async Task<Supply?> GetByIdAsync(int supplyId)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            SELECT s.*, sh.ShopName FROM dbo.Supply s
            INNER JOIN dbo.ShopMaster sh ON sh.ShopID = s.ShopID
            WHERE s.SupplyID = @SupplyID;

            SELECT si.*, f.FruitName, f.Unit FROM dbo.SupplyItems si
            INNER JOIN dbo.FruitMaster f ON f.FruitID = si.FruitID
            WHERE si.SupplyID = @SupplyID;
            """;
        using var multi = await connection.QueryMultipleAsync(sql, new { SupplyID = supplyId });
        var supply = await multi.ReadFirstOrDefaultAsync<Supply>();
        if (supply is null) return null;
        supply.Items = (await multi.ReadAsync<SupplyItem>()).ToList();
        return supply;
    }

    public async Task<PaginatedList<Supply>> GetPagedAsync(PaginationRequest request, int? shopId, DateTime? fromDate, DateTime? toDate)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            SELECT COUNT(*) FROM dbo.Supply s
            INNER JOIN dbo.ShopMaster sh ON sh.ShopID = s.ShopID
            WHERE (@ShopID IS NULL OR s.ShopID = @ShopID)
              AND (@FromDate IS NULL OR s.SupplyDate >= @FromDate)
              AND (@ToDate IS NULL OR s.SupplyDate <= @ToDate)
              AND (@SearchTerm IS NULL OR s.InvoiceNo LIKE @SearchPattern OR sh.ShopName LIKE @SearchPattern);

            SELECT s.*, sh.ShopName FROM dbo.Supply s
            INNER JOIN dbo.ShopMaster sh ON sh.ShopID = s.ShopID
            WHERE (@ShopID IS NULL OR s.ShopID = @ShopID)
              AND (@FromDate IS NULL OR s.SupplyDate >= @FromDate)
              AND (@ToDate IS NULL OR s.SupplyDate <= @ToDate)
              AND (@SearchTerm IS NULL OR s.InvoiceNo LIKE @SearchPattern OR sh.ShopName LIKE @SearchPattern)
            ORDER BY s.SupplyDate DESC, s.SupplyID DESC
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
        var items = (await multi.ReadAsync<Supply>()).ToList();
        return new PaginatedList<Supply>(items, total, request.PageNumber, request.PageSize);
    }

    public async Task<int> CreateAsync(Supply supply)
    {
        using var connection = connectionFactory.CreateConnection();
        connection.Open();
        using var transaction = connection.BeginTransaction();
        try
        {
            supply.TotalAmount = supply.Items.Sum(i => i.TotalAmount);

            const string insertSql = """
                INSERT INTO dbo.Supply (SupplyDate, ShopID, InvoiceNo, Remarks, TotalAmount, CreatedBy)
                OUTPUT INSERTED.SupplyID
                VALUES (@SupplyDate, @ShopID, @InvoiceNo, @Remarks, @TotalAmount, @CreatedBy);
                """;
            var supplyId = await connection.QuerySingleAsync<int>(insertSql, supply, transaction);

            const string insertItemSql = """
                INSERT INTO dbo.SupplyItems (SupplyID, FruitID, Quantity, UnitPrice, TotalAmount, BoxCount)
                VALUES (@SupplyID, @FruitID, @Quantity, @UnitPrice, @TotalAmount, @BoxCount);
                """;
            foreach (var item in supply.Items)
            {
                item.SupplyID = supplyId;
                await connection.ExecuteAsync(insertItemSql, item, transaction);
            }

            await ledgerService.AddShopLedgerEntryAsync(connection, transaction, supply.ShopID, supply.SupplyDate,
                LedgerTransactionTypes.Supply, supplyId, supply.TotalAmount, 0, $"Supply Invoice #{supply.InvoiceNo}");
            await ledgerService.RecalculateShopLedgerAsync(connection, transaction, supply.ShopID);

            var linkedSupplierId = await connection.ExecuteScalarAsync<int?>(
                "SELECT LinkedSupplierID FROM dbo.ShopMaster WHERE ShopID = @ShopID", new { supply.ShopID }, transaction);
            if (linkedSupplierId is not null)
            {
                var shopName = await connection.ExecuteScalarAsync<string>(
                    "SELECT ShopName FROM dbo.ShopMaster WHERE ShopID = @ShopID", new { supply.ShopID }, transaction);
                await ledgerService.AddSupplierLedgerEntryAsync(connection, transaction, linkedSupplierId.Value, supply.SupplyDate,
                    LedgerTransactionTypes.LinkedShopSale, supplyId, 0, supply.TotalAmount,
                    $"Sale to linked shop {shopName} (Invoice #{supply.InvoiceNo})");
                await ledgerService.RecalculateSupplierLedgerAsync(connection, transaction, linkedSupplierId.Value);
            }

            foreach (var item in supply.Items)
            {
                await ledgerService.AddStockLedgerEntryAsync(connection, transaction, item.FruitID, supply.SupplyDate,
                    LedgerTransactionTypes.Supply, ReferenceTables.Supply, supplyId, 0, item.Quantity, $"Supply Invoice #{supply.InvoiceNo}");
            }
            foreach (var fruitId in supply.Items.Select(i => i.FruitID).Distinct())
            {
                await ledgerService.RecalculateStockLedgerAsync(connection, transaction, fruitId);
                await ledgerService.RecalculateFruitCostBasisAsync(connection, transaction, fruitId);
                await ledgerService.RecalculateFruitBoxesAsync(connection, transaction, fruitId);
            }

            transaction.Commit();
            return supplyId;
        }
        catch
        {
            transaction.Rollback();
            throw;
        }
    }

    public async Task UpdateAsync(Supply supply)
    {
        using var connection = connectionFactory.CreateConnection();
        connection.Open();
        using var transaction = connection.BeginTransaction();
        try
        {
            var oldShopId = await connection.ExecuteScalarAsync<int>(
                "SELECT ShopID FROM dbo.Supply WHERE SupplyID = @SupplyID", new { supply.SupplyID }, transaction);
            var oldFruitIds = (await connection.QueryAsync<int>(
                "SELECT DISTINCT FruitID FROM dbo.SupplyItems WHERE SupplyID = @SupplyID", new { supply.SupplyID }, transaction)).ToList();
            var oldLinkedSupplierId = await connection.ExecuteScalarAsync<int?>(
                "SELECT LinkedSupplierID FROM dbo.ShopMaster WHERE ShopID = @ShopID", new { ShopID = oldShopId }, transaction);

            supply.TotalAmount = supply.Items.Sum(i => i.TotalAmount);

            const string updateSql = """
                UPDATE dbo.Supply
                SET SupplyDate = @SupplyDate, ShopID = @ShopID, InvoiceNo = @InvoiceNo,
                    Remarks = @Remarks, TotalAmount = @TotalAmount, UpdatedAt = SYSUTCDATETIME()
                WHERE SupplyID = @SupplyID;
                """;
            await connection.ExecuteAsync(updateSql, supply, transaction);

            await connection.ExecuteAsync("DELETE FROM dbo.SupplyItems WHERE SupplyID = @SupplyID", new { supply.SupplyID }, transaction);

            const string insertItemSql = """
                INSERT INTO dbo.SupplyItems (SupplyID, FruitID, Quantity, UnitPrice, TotalAmount, BoxCount)
                VALUES (@SupplyID, @FruitID, @Quantity, @UnitPrice, @TotalAmount, @BoxCount);
                """;
            foreach (var item in supply.Items)
            {
                item.SupplyID = supply.SupplyID;
                await connection.ExecuteAsync(insertItemSql, item, transaction);
            }

            await ledgerService.RemoveShopLedgerEntriesForReferenceAsync(connection, transaction, LedgerTransactionTypes.Supply, supply.SupplyID);
            await ledgerService.AddShopLedgerEntryAsync(connection, transaction, supply.ShopID, supply.SupplyDate,
                LedgerTransactionTypes.Supply, supply.SupplyID, supply.TotalAmount, 0, $"Supply Invoice #{supply.InvoiceNo}");

            await ledgerService.RecalculateShopLedgerAsync(connection, transaction, supply.ShopID);
            if (oldShopId != supply.ShopID)
            {
                await ledgerService.RecalculateShopLedgerAsync(connection, transaction, oldShopId);
            }

            await ledgerService.RemoveSupplierLedgerEntriesForReferenceAsync(connection, transaction, LedgerTransactionTypes.LinkedShopSale, supply.SupplyID);
            var newLinkedSupplierId = await connection.ExecuteScalarAsync<int?>(
                "SELECT LinkedSupplierID FROM dbo.ShopMaster WHERE ShopID = @ShopID", new { supply.ShopID }, transaction);
            if (newLinkedSupplierId is not null)
            {
                var shopName = await connection.ExecuteScalarAsync<string>(
                    "SELECT ShopName FROM dbo.ShopMaster WHERE ShopID = @ShopID", new { supply.ShopID }, transaction);
                await ledgerService.AddSupplierLedgerEntryAsync(connection, transaction, newLinkedSupplierId.Value, supply.SupplyDate,
                    LedgerTransactionTypes.LinkedShopSale, supply.SupplyID, 0, supply.TotalAmount,
                    $"Sale to linked shop {shopName} (Invoice #{supply.InvoiceNo})");
            }
            foreach (var supplierId in new[] { oldLinkedSupplierId, newLinkedSupplierId }.Where(id => id is not null).Select(id => id!.Value).Distinct())
            {
                await ledgerService.RecalculateSupplierLedgerAsync(connection, transaction, supplierId);
            }

            await ledgerService.RemoveStockLedgerEntriesForReferenceAsync(connection, transaction, ReferenceTables.Supply, supply.SupplyID);
            foreach (var item in supply.Items)
            {
                await ledgerService.AddStockLedgerEntryAsync(connection, transaction, item.FruitID, supply.SupplyDate,
                    LedgerTransactionTypes.Supply, ReferenceTables.Supply, supply.SupplyID, 0, item.Quantity, $"Supply Invoice #{supply.InvoiceNo}");
            }
            var newFruitIds = supply.Items.Select(i => i.FruitID).Distinct();
            foreach (var fruitId in oldFruitIds.Union(newFruitIds))
            {
                await ledgerService.RecalculateStockLedgerAsync(connection, transaction, fruitId);
                await ledgerService.RecalculateFruitCostBasisAsync(connection, transaction, fruitId);
                await ledgerService.RecalculateFruitBoxesAsync(connection, transaction, fruitId);
            }

            transaction.Commit();
        }
        catch
        {
            transaction.Rollback();
            throw;
        }
    }

    public async Task DeleteAsync(int supplyId)
    {
        using var connection = connectionFactory.CreateConnection();
        connection.Open();
        using var transaction = connection.BeginTransaction();
        try
        {
            var shopId = await connection.ExecuteScalarAsync<int>(
                "SELECT ShopID FROM dbo.Supply WHERE SupplyID = @SupplyID", new { SupplyID = supplyId }, transaction);
            var fruitIds = (await connection.QueryAsync<int>(
                "SELECT DISTINCT FruitID FROM dbo.SupplyItems WHERE SupplyID = @SupplyID", new { SupplyID = supplyId }, transaction)).ToList();
            var linkedSupplierId = await connection.ExecuteScalarAsync<int?>(
                "SELECT LinkedSupplierID FROM dbo.ShopMaster WHERE ShopID = @ShopID", new { ShopID = shopId }, transaction);

            await ledgerService.RemoveShopLedgerEntriesForReferenceAsync(connection, transaction, LedgerTransactionTypes.Supply, supplyId);
            await ledgerService.RemoveSupplierLedgerEntriesForReferenceAsync(connection, transaction, LedgerTransactionTypes.LinkedShopSale, supplyId);
            await ledgerService.RemoveStockLedgerEntriesForReferenceAsync(connection, transaction, ReferenceTables.Supply, supplyId);
            await connection.ExecuteAsync("DELETE FROM dbo.Supply WHERE SupplyID = @SupplyID", new { SupplyID = supplyId }, transaction);
            await ledgerService.RecalculateShopLedgerAsync(connection, transaction, shopId);
            if (linkedSupplierId is not null)
            {
                await ledgerService.RecalculateSupplierLedgerAsync(connection, transaction, linkedSupplierId.Value);
            }
            foreach (var fruitId in fruitIds)
            {
                await ledgerService.RecalculateStockLedgerAsync(connection, transaction, fruitId);
                await ledgerService.RecalculateFruitCostBasisAsync(connection, transaction, fruitId);
                await ledgerService.RecalculateFruitBoxesAsync(connection, transaction, fruitId);
            }

            transaction.Commit();
        }
        catch
        {
            transaction.Rollback();
            throw;
        }
    }

    public async Task<bool> InvoiceNoExistsAsync(string invoiceNo, int? excludeSupplyId = null)
    {
        using var connection = connectionFactory.CreateConnection();
        return await connection.ExecuteScalarAsync<bool>(
            "SELECT CASE WHEN EXISTS (SELECT 1 FROM dbo.Supply WHERE InvoiceNo = @InvoiceNo AND (@ExcludeSupplyId IS NULL OR SupplyID <> @ExcludeSupplyId)) THEN 1 ELSE 0 END",
            new { InvoiceNo = invoiceNo, ExcludeSupplyId = excludeSupplyId });
    }

    public async Task<string> GenerateNextInvoiceNoAsync()
    {
        using var connection = connectionFactory.CreateConnection();
        var maxSeq = await connection.ExecuteScalarAsync<int?>("""
            SELECT MAX(TRY_CAST(SUBSTRING(InvoiceNo, 4, 20) AS INT))
            FROM dbo.Supply
            WHERE InvoiceNo LIKE 'SUP%'
            """);
        return $"SUP{(maxSeq ?? 0) + 1:D6}";
    }

    public async Task<SupplyBillExtrasDto> GetBillExtrasAsync(int supplyId)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            SELECT ISNULL((
                SELECT TOP 1 RunningBalance - Debit FROM dbo.ShopLedger
                WHERE TransactionType = @TransactionType AND ReferenceID = @SupplyID
            ), 0) AS OldBalance,
            ISNULL((
                SELECT SUM(c.AmountReceived) FROM dbo.Collections c
                INNER JOIN dbo.Supply s ON s.SupplyID = @SupplyID
                WHERE c.ShopID = s.ShopID
                  AND CAST(c.CollectionDate AS DATE) = CAST(s.SupplyDate AS DATE)
                  AND c.CollectionType = @CollectionType
            ), 0) AS SuggestedCashReceived;
            """;
        return await connection.QuerySingleAsync<SupplyBillExtrasDto>(sql,
            new { SupplyID = supplyId, TransactionType = LedgerTransactionTypes.Supply, CollectionType = CollectionTypes.Normal });
    }
}
