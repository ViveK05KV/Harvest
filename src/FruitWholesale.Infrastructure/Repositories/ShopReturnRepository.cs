using System.Data;
using Dapper;
using FruitWholesale.Application.Common.Interfaces;
using FruitWholesale.Domain.Entities;
using FruitWholesale.Domain.Enums;
using FruitWholesale.Shared.Pagination;

namespace FruitWholesale.Infrastructure.Repositories;

public class ShopReturnRepository(IDbConnectionFactory connectionFactory, ILedgerService ledgerService) : IShopReturnRepository
{
    public async Task<ShopReturn?> GetByIdAsync(int shopReturnId)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            SELECT r.*, sh.ShopName, s.InvoiceNo AS SupplyInvoiceNo FROM dbo.ShopReturns r
            INNER JOIN dbo.ShopMaster sh ON sh.ShopID = r.ShopID
            LEFT JOIN dbo.Supply s ON s.SupplyID = r.SupplyID
            WHERE r.ShopReturnID = @ShopReturnID;

            SELECT ri.*, f.FruitName, f.Unit FROM dbo.ShopReturnItems ri
            INNER JOIN dbo.FruitMaster f ON f.FruitID = ri.FruitID
            WHERE ri.ShopReturnID = @ShopReturnID;
            """;
        using var multi = await connection.QueryMultipleAsync(sql, new { ShopReturnID = shopReturnId });
        var shopReturn = await multi.ReadFirstOrDefaultAsync<ShopReturn>();
        if (shopReturn is null) return null;
        shopReturn.Items = (await multi.ReadAsync<ShopReturnItem>()).ToList();
        return shopReturn;
    }

    public async Task<PaginatedList<ShopReturn>> GetPagedAsync(PaginationRequest request, int? shopId, DateTime? fromDate, DateTime? toDate)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            SELECT COUNT(*) FROM dbo.ShopReturns r
            INNER JOIN dbo.ShopMaster sh ON sh.ShopID = r.ShopID
            WHERE (@ShopID IS NULL OR r.ShopID = @ShopID)
              AND (@FromDate IS NULL OR r.ReturnDate >= @FromDate)
              AND (@ToDate IS NULL OR r.ReturnDate <= @ToDate)
              AND (@SearchTerm IS NULL OR r.ReferenceNo LIKE @SearchPattern OR sh.ShopName LIKE @SearchPattern);

            SELECT r.*, sh.ShopName, s.InvoiceNo AS SupplyInvoiceNo FROM dbo.ShopReturns r
            INNER JOIN dbo.ShopMaster sh ON sh.ShopID = r.ShopID
            LEFT JOIN dbo.Supply s ON s.SupplyID = r.SupplyID
            WHERE (@ShopID IS NULL OR r.ShopID = @ShopID)
              AND (@FromDate IS NULL OR r.ReturnDate >= @FromDate)
              AND (@ToDate IS NULL OR r.ReturnDate <= @ToDate)
              AND (@SearchTerm IS NULL OR r.ReferenceNo LIKE @SearchPattern OR sh.ShopName LIKE @SearchPattern)
            ORDER BY r.ReturnDate DESC, r.ShopReturnID DESC
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
        var items = (await multi.ReadAsync<ShopReturn>()).ToList();
        return new PaginatedList<ShopReturn>(items, total, request.PageNumber, request.PageSize);
    }

    public async Task<int> CreateAsync(ShopReturn shopReturn)
    {
        using var connection = connectionFactory.CreateConnection();
        connection.Open();
        using var transaction = connection.BeginTransaction();
        try
        {
            shopReturn.TotalAmount = shopReturn.Items.Sum(i => i.TotalAmount);

            const string insertSql = """
                INSERT INTO dbo.ShopReturns (ReturnDate, ShopID, SupplyID, ReferenceNo, Remarks, TotalAmount, CreatedBy)
                OUTPUT INSERTED.ShopReturnID
                VALUES (@ReturnDate, @ShopID, @SupplyID, @ReferenceNo, @Remarks, @TotalAmount, @CreatedBy);
                """;
            var shopReturnId = await connection.QuerySingleAsync<int>(insertSql, shopReturn, transaction);

            const string insertItemSql = """
                INSERT INTO dbo.ShopReturnItems (ShopReturnID, FruitID, Quantity, UnitPrice, TotalAmount, CostBasis)
                VALUES (@ShopReturnID, @FruitID, @Quantity, @UnitPrice, @TotalAmount, @CostBasis);
                """;
            var costBasisByFruit = await ResolveReturnCostBasisBatchAsync(
                connection, transaction, shopReturn.Items.Select(i => i.FruitID).Distinct(), shopReturn.SupplyID);
            foreach (var item in shopReturn.Items)
            {
                item.ShopReturnID = shopReturnId;
                item.CostBasis = costBasisByFruit.GetValueOrDefault(item.FruitID);
                await connection.ExecuteAsync(insertItemSql, item, transaction);
            }

            await ledgerService.AddShopLedgerEntryAsync(connection, transaction, shopReturn.ShopID, shopReturn.ReturnDate,
                LedgerTransactionTypes.ShopReturn, shopReturnId, 0, shopReturn.TotalAmount, $"Shop Return #{shopReturn.ReferenceNo}");
            await ledgerService.RecalculateShopLedgerAsync(connection, transaction, shopReturn.ShopID);

            foreach (var item in shopReturn.Items)
            {
                await ledgerService.AddStockLedgerEntryAsync(connection, transaction, item.FruitID, shopReturn.ReturnDate,
                    LedgerTransactionTypes.ShopReturn, ReferenceTables.ShopReturns, shopReturnId, item.Quantity, 0, $"Shop Return #{shopReturn.ReferenceNo}");
            }
            foreach (var fruitId in shopReturn.Items.Select(i => i.FruitID).Distinct())
            {
                await ledgerService.RecalculateStockLedgerAsync(connection, transaction, fruitId);
                await ledgerService.RecalculateFruitCostBasisAsync(connection, transaction, fruitId);
            }

            transaction.Commit();
            return shopReturnId;
        }
        catch
        {
            transaction.Rollback();
            throw;
        }
    }

    public async Task UpdateAsync(ShopReturn shopReturn)
    {
        using var connection = connectionFactory.CreateConnection();
        connection.Open();
        using var transaction = connection.BeginTransaction();
        try
        {
            var oldShopId = await connection.ExecuteScalarAsync<int>(
                "SELECT ShopID FROM dbo.ShopReturns WHERE ShopReturnID = @ShopReturnID", new { shopReturn.ShopReturnID }, transaction);
            var oldFruitIds = (await connection.QueryAsync<int>(
                "SELECT DISTINCT FruitID FROM dbo.ShopReturnItems WHERE ShopReturnID = @ShopReturnID", new { shopReturn.ShopReturnID }, transaction)).ToList();

            shopReturn.TotalAmount = shopReturn.Items.Sum(i => i.TotalAmount);

            const string updateSql = """
                UPDATE dbo.ShopReturns
                SET ReturnDate = @ReturnDate, ShopID = @ShopID, SupplyID = @SupplyID, ReferenceNo = @ReferenceNo,
                    Remarks = @Remarks, TotalAmount = @TotalAmount, UpdatedAt = SYSUTCDATETIME()
                WHERE ShopReturnID = @ShopReturnID;
                """;
            await connection.ExecuteAsync(updateSql, shopReturn, transaction);

            await connection.ExecuteAsync("DELETE FROM dbo.ShopReturnItems WHERE ShopReturnID = @ShopReturnID", new { shopReturn.ShopReturnID }, transaction);

            const string insertItemSql = """
                INSERT INTO dbo.ShopReturnItems (ShopReturnID, FruitID, Quantity, UnitPrice, TotalAmount, CostBasis)
                VALUES (@ShopReturnID, @FruitID, @Quantity, @UnitPrice, @TotalAmount, @CostBasis);
                """;
            var costBasisByFruit = await ResolveReturnCostBasisBatchAsync(
                connection, transaction, shopReturn.Items.Select(i => i.FruitID).Distinct(), shopReturn.SupplyID);
            foreach (var item in shopReturn.Items)
            {
                item.ShopReturnID = shopReturn.ShopReturnID;
                item.CostBasis = costBasisByFruit.GetValueOrDefault(item.FruitID);
                await connection.ExecuteAsync(insertItemSql, item, transaction);
            }

            await ledgerService.RemoveShopLedgerEntriesForReferenceAsync(connection, transaction, LedgerTransactionTypes.ShopReturn, shopReturn.ShopReturnID);
            await ledgerService.AddShopLedgerEntryAsync(connection, transaction, shopReturn.ShopID, shopReturn.ReturnDate,
                LedgerTransactionTypes.ShopReturn, shopReturn.ShopReturnID, 0, shopReturn.TotalAmount, $"Shop Return #{shopReturn.ReferenceNo}");

            await ledgerService.RecalculateShopLedgerAsync(connection, transaction, shopReturn.ShopID);
            if (oldShopId != shopReturn.ShopID)
            {
                await ledgerService.RecalculateShopLedgerAsync(connection, transaction, oldShopId);
            }

            await ledgerService.RemoveStockLedgerEntriesForReferenceAsync(connection, transaction, ReferenceTables.ShopReturns, shopReturn.ShopReturnID);
            foreach (var item in shopReturn.Items)
            {
                await ledgerService.AddStockLedgerEntryAsync(connection, transaction, item.FruitID, shopReturn.ReturnDate,
                    LedgerTransactionTypes.ShopReturn, ReferenceTables.ShopReturns, shopReturn.ShopReturnID, item.Quantity, 0, $"Shop Return #{shopReturn.ReferenceNo}");
            }
            var newFruitIds = shopReturn.Items.Select(i => i.FruitID).Distinct();
            foreach (var fruitId in oldFruitIds.Union(newFruitIds))
            {
                await ledgerService.RecalculateStockLedgerAsync(connection, transaction, fruitId);
                await ledgerService.RecalculateFruitCostBasisAsync(connection, transaction, fruitId);
            }

            transaction.Commit();
        }
        catch
        {
            transaction.Rollback();
            throw;
        }
    }

    public async Task DeleteAsync(int shopReturnId)
    {
        using var connection = connectionFactory.CreateConnection();
        connection.Open();
        using var transaction = connection.BeginTransaction();
        try
        {
            var shopId = await connection.ExecuteScalarAsync<int>(
                "SELECT ShopID FROM dbo.ShopReturns WHERE ShopReturnID = @ShopReturnID", new { ShopReturnID = shopReturnId }, transaction);
            var fruitIds = (await connection.QueryAsync<int>(
                "SELECT DISTINCT FruitID FROM dbo.ShopReturnItems WHERE ShopReturnID = @ShopReturnID", new { ShopReturnID = shopReturnId }, transaction)).ToList();

            await ledgerService.RemoveShopLedgerEntriesForReferenceAsync(connection, transaction, LedgerTransactionTypes.ShopReturn, shopReturnId);
            await ledgerService.RemoveStockLedgerEntriesForReferenceAsync(connection, transaction, ReferenceTables.ShopReturns, shopReturnId);
            await connection.ExecuteAsync("DELETE FROM dbo.ShopReturns WHERE ShopReturnID = @ShopReturnID", new { ShopReturnID = shopReturnId }, transaction);
            await ledgerService.RecalculateShopLedgerAsync(connection, transaction, shopId);
            foreach (var fruitId in fruitIds)
            {
                await ledgerService.RecalculateStockLedgerAsync(connection, transaction, fruitId);
                await ledgerService.RecalculateFruitCostBasisAsync(connection, transaction, fruitId);
            }

            transaction.Commit();
        }
        catch
        {
            transaction.Rollback();
            throw;
        }
    }

    public async Task<bool> ReferenceNoExistsAsync(string referenceNo, int? excludeShopReturnId = null)
    {
        using var connection = connectionFactory.CreateConnection();
        return await connection.ExecuteScalarAsync<bool>(
            "SELECT CASE WHEN EXISTS (SELECT 1 FROM dbo.ShopReturns WHERE ReferenceNo = @ReferenceNo AND (@ExcludeShopReturnId IS NULL OR ShopReturnID <> @ExcludeShopReturnId)) THEN 1 ELSE 0 END",
            new { ReferenceNo = referenceNo, ExcludeShopReturnId = excludeShopReturnId });
    }

    public async Task<string> GenerateNextReferenceNoAsync()
    {
        using var connection = connectionFactory.CreateConnection();
        var maxSeq = await connection.ExecuteScalarAsync<int?>("""
            SELECT MAX(TRY_CAST(SUBSTRING(ReferenceNo, 4, 20) AS INT))
            FROM dbo.ShopReturns
            WHERE ReferenceNo LIKE 'SRT%'
            """);
        return $"SRT{(maxSeq ?? 0) + 1:D6}";
    }

    /// <summary>
    /// Cost this returned stock re-enters inventory at, resolved for every
    /// distinct fruit on the return in two batched queries instead of one
    /// (or two) round trips per line item: the original sale's recorded
    /// CostBasis when the return is linked to a specific Supply invoice and
    /// that fruit was actually on it, otherwise the fruit's current average
    /// cost as the best available estimate.
    /// </summary>
    private static async Task<Dictionary<int, decimal>> ResolveReturnCostBasisBatchAsync(
        IDbConnection connection, IDbTransaction transaction, IEnumerable<int> fruitIds, int? supplyId)
    {
        var fruitIdList = fruitIds.ToList();
        var linked = supplyId.HasValue
            ? (await connection.QueryAsync<(int FruitID, decimal CostBasis)>(
                "SELECT FruitID, CostBasis FROM dbo.SupplyItems WHERE SupplyID = @SupplyID AND FruitID IN @FruitIds",
                new { SupplyID = supplyId, FruitIds = fruitIdList }, transaction)).ToDictionary(r => r.FruitID, r => r.CostBasis)
            : [];

        var unresolved = fruitIdList.Where(id => !linked.ContainsKey(id)).ToList();
        var averageCost = unresolved.Count == 0
            ? []
            : (await connection.QueryAsync<(int FruitID, decimal AverageCost)>(
                "SELECT FruitID, AverageCost FROM dbo.FruitCostBasis WHERE FruitID IN @FruitIds",
                new { FruitIds = unresolved }, transaction)).ToDictionary(r => r.FruitID, r => r.AverageCost);

        return fruitIdList.ToDictionary(id => id, id => linked.TryGetValue(id, out var lcb) ? lcb : averageCost.GetValueOrDefault(id));
    }
}
