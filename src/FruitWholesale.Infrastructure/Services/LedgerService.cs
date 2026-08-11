using System.Data;
using System.Text.Json;
using Dapper;
using FruitWholesale.Application.Common.Interfaces;
using FruitWholesale.Domain.Entities;
using FruitWholesale.Domain.Enums;

namespace FruitWholesale.Infrastructure.Services;

public class LedgerService(IDbConnectionFactory connectionFactory) : ILedgerService
{
    public async Task<decimal> AddShopLedgerEntryAsync(IDbConnection connection, IDbTransaction transaction, int shopId,
        DateTime transactionDate, string transactionType, int? referenceId, decimal debit, decimal credit, string narration)
    {
        const string previousBalanceSql = """
            SELECT TOP 1 RunningBalance FROM dbo.ShopLedger
            WHERE ShopID = @ShopID
            ORDER BY TransactionDate DESC, LedgerID DESC
            """;
        var previousBalance = await connection.QueryFirstOrDefaultAsync<decimal?>(previousBalanceSql, new { ShopID = shopId }, transaction) ?? 0m;
        var newBalance = previousBalance + debit - credit;

        const string insertSql = """
            INSERT INTO dbo.ShopLedger (ShopID, TransactionDate, TransactionType, ReferenceID, Debit, Credit, RunningBalance, Narration)
            VALUES (@ShopID, @TransactionDate, @TransactionType, @ReferenceID, @Debit, @Credit, @RunningBalance, @Narration);
            """;
        await connection.ExecuteAsync(insertSql, new
        {
            ShopID = shopId,
            TransactionDate = transactionDate,
            TransactionType = transactionType,
            ReferenceID = referenceId,
            Debit = debit,
            Credit = credit,
            RunningBalance = newBalance,
            Narration = narration
        }, transaction);

        return newBalance;
    }

    public async Task<decimal> AddSupplierLedgerEntryAsync(IDbConnection connection, IDbTransaction transaction, int supplierId,
        DateTime transactionDate, string transactionType, int? referenceId, decimal debit, decimal credit, string narration)
    {
        const string previousBalanceSql = """
            SELECT TOP 1 RunningBalance FROM dbo.SupplierLedger
            WHERE SupplierID = @SupplierID
            ORDER BY TransactionDate DESC, LedgerID DESC
            """;
        var previousBalance = await connection.QueryFirstOrDefaultAsync<decimal?>(previousBalanceSql, new { SupplierID = supplierId }, transaction) ?? 0m;
        var newBalance = previousBalance + debit - credit;

        const string insertSql = """
            INSERT INTO dbo.SupplierLedger (SupplierID, TransactionDate, TransactionType, ReferenceID, Debit, Credit, RunningBalance, Narration)
            VALUES (@SupplierID, @TransactionDate, @TransactionType, @ReferenceID, @Debit, @Credit, @RunningBalance, @Narration);
            """;
        await connection.ExecuteAsync(insertSql, new
        {
            SupplierID = supplierId,
            TransactionDate = transactionDate,
            TransactionType = transactionType,
            ReferenceID = referenceId,
            Debit = debit,
            Credit = credit,
            RunningBalance = newBalance,
            Narration = narration
        }, transaction);

        return newBalance;
    }

    public async Task<decimal> AddCashLedgerEntryAsync(IDbConnection connection, IDbTransaction transaction,
        DateTime transactionDate, string transactionType, string referenceTable, int? referenceId,
        string paymentMode, decimal cashIn, decimal cashOut, string narration)
    {
        const string previousBalanceSql = """
            SELECT TOP 1 RunningBalance FROM dbo.CashLedger
            ORDER BY TransactionDate DESC, CashLedgerID DESC
            """;
        var previousBalance = await connection.QueryFirstOrDefaultAsync<decimal?>(previousBalanceSql, transaction: transaction) ?? 0m;
        var newBalance = previousBalance + cashIn - cashOut;

        const string insertSql = """
            INSERT INTO dbo.CashLedger (TransactionDate, TransactionType, ReferenceTable, ReferenceID, PaymentMode, CashIn, CashOut, RunningBalance, Narration)
            VALUES (@TransactionDate, @TransactionType, @ReferenceTable, @ReferenceID, @PaymentMode, @CashIn, @CashOut, @RunningBalance, @Narration);
            """;
        await connection.ExecuteAsync(insertSql, new
        {
            TransactionDate = transactionDate,
            TransactionType = transactionType,
            ReferenceTable = referenceTable,
            ReferenceID = referenceId,
            PaymentMode = paymentMode,
            CashIn = cashIn,
            CashOut = cashOut,
            RunningBalance = newBalance,
            Narration = narration
        }, transaction);

        return newBalance;
    }

    public Task RemoveShopLedgerEntriesForReferenceAsync(IDbConnection connection, IDbTransaction transaction, string transactionType, int referenceId) =>
        connection.ExecuteAsync(
            "DELETE FROM dbo.ShopLedger WHERE TransactionType = @TransactionType AND ReferenceID = @ReferenceID",
            new { TransactionType = transactionType, ReferenceID = referenceId }, transaction);

    public Task RemoveSupplierLedgerEntriesForReferenceAsync(IDbConnection connection, IDbTransaction transaction, string transactionType, int referenceId) =>
        connection.ExecuteAsync(
            "DELETE FROM dbo.SupplierLedger WHERE TransactionType = @TransactionType AND ReferenceID = @ReferenceID",
            new { TransactionType = transactionType, ReferenceID = referenceId }, transaction);

    public Task RemoveCashLedgerEntriesForReferenceAsync(IDbConnection connection, IDbTransaction transaction, string referenceTable, int referenceId) =>
        connection.ExecuteAsync(
            "DELETE FROM dbo.CashLedger WHERE ReferenceTable = @ReferenceTable AND ReferenceID = @ReferenceID",
            new { ReferenceTable = referenceTable, ReferenceID = referenceId }, transaction);

    public Task<int> DeleteShopLedgerAdjustmentAsync(IDbConnection connection, IDbTransaction transaction, int shopId, long ledgerId) =>
        connection.ExecuteAsync(
            "DELETE FROM dbo.ShopLedger WHERE LedgerID = @LedgerID AND ShopID = @ShopID AND TransactionType = 'Adjustment'",
            new { LedgerID = ledgerId, ShopID = shopId }, transaction);

    public Task<int> DeleteSupplierLedgerAdjustmentAsync(IDbConnection connection, IDbTransaction transaction, int supplierId, long ledgerId) =>
        connection.ExecuteAsync(
            "DELETE FROM dbo.SupplierLedger WHERE LedgerID = @LedgerID AND SupplierID = @SupplierID AND TransactionType = 'Adjustment'",
            new { LedgerID = ledgerId, SupplierID = supplierId }, transaction);

    public Task RecalculateShopLedgerAsync(IDbConnection connection, IDbTransaction transaction, int shopId) =>
        connection.ExecuteAsync("dbo.sp_RecalculateShopLedgerBalance", new { ShopID = shopId },
            transaction, commandType: CommandType.StoredProcedure);

    public Task RecalculateSupplierLedgerAsync(IDbConnection connection, IDbTransaction transaction, int supplierId) =>
        connection.ExecuteAsync("dbo.sp_RecalculateSupplierLedgerBalance", new { SupplierID = supplierId },
            transaction, commandType: CommandType.StoredProcedure);

    public Task RecalculateCashLedgerAsync(IDbConnection connection, IDbTransaction transaction) =>
        connection.ExecuteAsync("dbo.sp_RecalculateCashLedgerBalance", transaction: transaction, commandType: CommandType.StoredProcedure);

    public async Task<decimal> GetShopOutstandingAsync(int shopId)
    {
        using var connection = connectionFactory.CreateConnection();
        // Must rank rows the same way sp_RecalculateShopLedgerBalance does: the opening
        // balance/adjustment row is forced first regardless of its own TransactionDate, so a
        // naive "latest TransactionDate" pick can land back on that row instead of the true
        // final one. See GetCurrentCashBalanceAsync for the same pattern on CashLedger.
        const string sql = """
            DECLARE @FirstLedgerID BIGINT = (SELECT MIN(LedgerID) FROM dbo.ShopLedger WHERE ShopID = @ShopID);
            SELECT TOP 1 RunningBalance
            FROM dbo.ShopLedger
            WHERE ShopID = @ShopID
            ORDER BY
                CASE
                    WHEN LedgerID = @FirstLedgerID AND TransactionType IN ('OpeningBalance', 'Adjustment') THEN 0
                    ELSE 1
                END DESC,
                TransactionDate DESC,
                LedgerID DESC;
            """;
        return await connection.QueryFirstOrDefaultAsync<decimal?>(sql, new { ShopID = shopId }) ?? 0m;
    }

    public async Task<Dictionary<int, decimal>> GetShopOutstandingBatchAsync(IEnumerable<int> shopIds)
    {
        var ids = shopIds.Distinct().ToList();
        if (ids.Count == 0) return [];

        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            ;WITH Ranked AS (
                SELECT ShopID, LedgerID, TransactionType, TransactionDate, RunningBalance,
                       MIN(LedgerID) OVER (PARTITION BY ShopID) AS FirstLedgerID
                FROM dbo.ShopLedger
                WHERE ShopID IN @ShopIDs
            )
            SELECT ShopID, RunningBalance
            FROM (
                SELECT ShopID, RunningBalance,
                       ROW_NUMBER() OVER (
                           PARTITION BY ShopID
                           ORDER BY
                               CASE
                                   WHEN LedgerID = FirstLedgerID AND TransactionType IN ('OpeningBalance', 'Adjustment') THEN 0
                                   ELSE 1
                               END DESC,
                               TransactionDate DESC,
                               LedgerID DESC
                       ) AS rn
                FROM Ranked
            ) x
            WHERE rn = 1;
            """;
        var rows = await connection.QueryAsync<(int ShopID, decimal RunningBalance)>(sql, new { ShopIDs = ids });
        return rows.ToDictionary(r => r.ShopID, r => r.RunningBalance);
    }

    public async Task<decimal> GetSupplierOutstandingAsync(int supplierId)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            DECLARE @FirstLedgerID BIGINT = (SELECT MIN(LedgerID) FROM dbo.SupplierLedger WHERE SupplierID = @SupplierID);
            SELECT TOP 1 RunningBalance
            FROM dbo.SupplierLedger
            WHERE SupplierID = @SupplierID
            ORDER BY
                CASE
                    WHEN LedgerID = @FirstLedgerID AND TransactionType IN ('OpeningBalance', 'Adjustment') THEN 0
                    ELSE 1
                END DESC,
                TransactionDate DESC,
                LedgerID DESC;
            """;
        return await connection.QueryFirstOrDefaultAsync<decimal?>(sql, new { SupplierID = supplierId }) ?? 0m;
    }

    public async Task<Dictionary<int, decimal>> GetSupplierOutstandingBatchAsync(IEnumerable<int> supplierIds)
    {
        var ids = supplierIds.Distinct().ToList();
        if (ids.Count == 0) return [];

        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            ;WITH Ranked AS (
                SELECT SupplierID, LedgerID, TransactionType, TransactionDate, RunningBalance,
                       MIN(LedgerID) OVER (PARTITION BY SupplierID) AS FirstLedgerID
                FROM dbo.SupplierLedger
                WHERE SupplierID IN @SupplierIDs
            )
            SELECT SupplierID, RunningBalance
            FROM (
                SELECT SupplierID, RunningBalance,
                       ROW_NUMBER() OVER (
                           PARTITION BY SupplierID
                           ORDER BY
                               CASE
                                   WHEN LedgerID = FirstLedgerID AND TransactionType IN ('OpeningBalance', 'Adjustment') THEN 0
                                   ELSE 1
                               END DESC,
                               TransactionDate DESC,
                               LedgerID DESC
                       ) AS rn
                FROM Ranked
            ) x
            WHERE rn = 1;
            """;
        var rows = await connection.QueryAsync<(int SupplierID, decimal RunningBalance)>(sql, new { SupplierIDs = ids });
        return rows.ToDictionary(r => r.SupplierID, r => r.RunningBalance);
    }


    public async Task<PaginatedLedger<ShopLedger>> GetShopLedgerAsync(int shopId, DateTime? fromDate, DateTime? toDate, int pageNumber, int pageSize)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            SELECT COUNT(*) FROM dbo.ShopLedger
            WHERE ShopID = @ShopID
              AND (@FromDate IS NULL OR TransactionDate >= @FromDate)
              AND (@ToDate IS NULL OR TransactionDate < DATEADD(DAY, 1, @ToDate));

            SELECT * FROM dbo.ShopLedger
            WHERE ShopID = @ShopID
              AND (@FromDate IS NULL OR TransactionDate >= @FromDate)
              AND (@ToDate IS NULL OR TransactionDate < DATEADD(DAY, 1, @ToDate))
            ORDER BY TransactionDate ASC, LedgerID ASC
            OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;
            """;
        using var multi = await connection.QueryMultipleAsync(sql, new
        {
            ShopID = shopId,
            FromDate = fromDate,
            ToDate = toDate,
            Offset = (pageNumber - 1) * pageSize,
            PageSize = pageSize
        });
        var total = await multi.ReadSingleAsync<int>();
        var items = (await multi.ReadAsync<ShopLedger>()).ToList();
        return new PaginatedLedger<ShopLedger> { Items = items, TotalCount = total };
    }

    public async Task<PaginatedLedger<SupplierLedger>> GetSupplierLedgerAsync(int supplierId, DateTime? fromDate, DateTime? toDate, int pageNumber, int pageSize)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            SELECT COUNT(*) FROM dbo.SupplierLedger
            WHERE SupplierID = @SupplierID
              AND (@FromDate IS NULL OR TransactionDate >= @FromDate)
              AND (@ToDate IS NULL OR TransactionDate < DATEADD(DAY, 1, @ToDate));

            SELECT * FROM dbo.SupplierLedger
            WHERE SupplierID = @SupplierID
              AND (@FromDate IS NULL OR TransactionDate >= @FromDate)
              AND (@ToDate IS NULL OR TransactionDate < DATEADD(DAY, 1, @ToDate))
            ORDER BY TransactionDate ASC, LedgerID ASC
            OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;
            """;
        using var multi = await connection.QueryMultipleAsync(sql, new
        {
            SupplierID = supplierId,
            FromDate = fromDate,
            ToDate = toDate,
            Offset = (pageNumber - 1) * pageSize,
            PageSize = pageSize
        });
        var total = await multi.ReadSingleAsync<int>();
        var items = (await multi.ReadAsync<SupplierLedger>()).ToList();
        return new PaginatedLedger<SupplierLedger> { Items = items, TotalCount = total };
    }

    public async Task<PaginatedLedger<CashLedger>> GetCashLedgerAsync(DateTime? fromDate, DateTime? toDate, string? transactionType, bool newestFirst, int pageNumber, int pageSize)
    {
        using var connection = connectionFactory.CreateConnection();
        // The opening-balance row (see sp_RecalculateCashLedgerBalance for the exact rule - the
        // very first CashLedger row ever, if it's an OpeningBalance or Adjustment entry) is always
        // ranked first, independent of @NewestFirst - accounting ledgers anchor it at the top
        // regardless of sort direction. RunningBalance itself is precomputed by that same
        // procedure on every write, so reversing display order here is a pure re-sort: it never
        // touches the stored balances, and paging in either direction stays consistent (Option A
        // from the ledger rewrite - calculate over the full filtered set, then paginate).
        const string sql = """
            DECLARE @FirstCashLedgerID BIGINT = (SELECT MIN(CashLedgerID) FROM dbo.CashLedger);

            SELECT COUNT(*) FROM dbo.CashLedger
            WHERE (@FromDate IS NULL OR TransactionDate >= @FromDate)
              AND (@ToDate IS NULL OR TransactionDate < DATEADD(DAY, 1, @ToDate))
              AND (@TransactionType IS NULL OR TransactionType = @TransactionType);

            SELECT * FROM dbo.CashLedger
            WHERE (@FromDate IS NULL OR TransactionDate >= @FromDate)
              AND (@ToDate IS NULL OR TransactionDate < DATEADD(DAY, 1, @ToDate))
              AND (@TransactionType IS NULL OR TransactionType = @TransactionType)
            ORDER BY
                CASE
                    WHEN CashLedgerID = @FirstCashLedgerID AND TransactionType IN ('OpeningBalance', 'Adjustment') THEN 0
                    ELSE 1
                END,
                CASE WHEN @NewestFirst = 0 THEN TransactionDate END ASC,
                CASE WHEN @NewestFirst = 1 THEN TransactionDate END DESC,
                CASE WHEN @NewestFirst = 0 THEN CashLedgerID END ASC,
                CASE WHEN @NewestFirst = 1 THEN CashLedgerID END DESC
            OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;
            """;
        using var multi = await connection.QueryMultipleAsync(sql, new
        {
            FromDate = fromDate,
            ToDate = toDate,
            TransactionType = transactionType,
            NewestFirst = newestFirst,
            Offset = (pageNumber - 1) * pageSize,
            PageSize = pageSize
        });
        var total = await multi.ReadSingleAsync<int>();
        var items = (await multi.ReadAsync<CashLedger>()).ToList();
        return new PaginatedLedger<CashLedger> { Items = items, TotalCount = total };
    }

    public async Task<decimal> GetCurrentCashBalanceAsync()
    {
        using var connection = connectionFactory.CreateConnection();
        // Must rank rows the same way sp_RecalculateCashLedgerBalance does: the opening
        // balance/adjustment row is forced first regardless of its own TransactionDate (it can be
        // stamped with today's date even though it represents the earliest balance), so a naive
        // "latest TransactionDate" pick can land back on that row instead of the true final one.
        const string sql = """
            DECLARE @FirstCashLedgerID BIGINT = (SELECT MIN(CashLedgerID) FROM dbo.CashLedger);
            SELECT TOP 1 RunningBalance
            FROM dbo.CashLedger
            ORDER BY
                CASE
                    WHEN CashLedgerID = @FirstCashLedgerID AND TransactionType IN ('OpeningBalance', 'Adjustment') THEN 0
                    ELSE 1
                END DESC,
                TransactionDate DESC,
                CashLedgerID DESC;
            """;
        return await connection.QueryFirstOrDefaultAsync<decimal?>(sql) ?? 0m;
    }

    public async Task<decimal> AddStockLedgerEntryAsync(IDbConnection connection, IDbTransaction transaction, int fruitId,
        DateTime transactionDate, string transactionType, string referenceTable, int? referenceId,
        decimal quantityIn, decimal quantityOut, string narration)
    {
        const string previousStockSql = """
            SELECT TOP 1 RunningStock FROM dbo.StockLedger
            WHERE FruitID = @FruitID
            ORDER BY TransactionDate DESC, StockLedgerID DESC
            """;
        var previousStock = await connection.QueryFirstOrDefaultAsync<decimal?>(previousStockSql, new { FruitID = fruitId }, transaction) ?? 0m;
        var newStock = previousStock + quantityIn - quantityOut;

        const string insertSql = """
            INSERT INTO dbo.StockLedger (FruitID, TransactionDate, TransactionType, ReferenceTable, ReferenceID, QuantityIn, QuantityOut, RunningStock, Narration)
            VALUES (@FruitID, @TransactionDate, @TransactionType, @ReferenceTable, @ReferenceID, @QuantityIn, @QuantityOut, @RunningStock, @Narration);
            """;
        await connection.ExecuteAsync(insertSql, new
        {
            FruitID = fruitId,
            TransactionDate = transactionDate,
            TransactionType = transactionType,
            ReferenceTable = referenceTable,
            ReferenceID = referenceId,
            QuantityIn = quantityIn,
            QuantityOut = quantityOut,
            RunningStock = newStock,
            Narration = narration
        }, transaction);

        return newStock;
    }

    public Task RemoveStockLedgerEntriesForReferenceAsync(IDbConnection connection, IDbTransaction transaction, string referenceTable, int referenceId) =>
        connection.ExecuteAsync(
            "DELETE FROM dbo.StockLedger WHERE ReferenceTable = @ReferenceTable AND ReferenceID = @ReferenceID",
            new { ReferenceTable = referenceTable, ReferenceID = referenceId }, transaction);

    public Task RecalculateStockLedgerAsync(IDbConnection connection, IDbTransaction transaction, int fruitId) =>
        connection.ExecuteAsync("dbo.sp_RecalculateStockLedgerBalance", new { FruitID = fruitId },
            transaction, commandType: CommandType.StoredProcedure);

    public async Task RecalculateFruitCostBasisAsync(IDbConnection connection, IDbTransaction transaction, int fruitId)
    {
        // Inflow events (Purchase, ShopReturn) blend into the weighted average using their
        // own UnitCost. Outflow events (Supply, SupplierReturn) consume stock at whatever the
        // average is at that moment and snapshot it onto their own row — never the other
        // way round — so a later purchase/return never retroactively changes profit already
        // booked on a past sale/return. See database/08_AddProfitTracking.sql and
        // database/09_AddReturns.sql for the full rationale.
        //
        // Purchase UnitCost is TotalAmount/Quantity, not PurchasePrice directly: for
        // box-tracked fruits PurchasePrice is entered per BOX, while Quantity is always in
        // kg, so using PurchasePrice as-is would price the whole kg quantity at the per-box
        // rate. TotalAmount is already correctly BoxCount*PurchasePrice (or Quantity*Price
        // for kg-rate fruits), so dividing by Quantity always yields the true per-kg cost.
        const string eventsSql = """
            SELECT 'PURCHASE' AS EventType, pi.PurchaseItemID AS ItemID, p.PurchaseDate AS TransactionDate,
                   p.CreatedAt AS ParentCreatedAt, pi.Quantity, pi.TotalAmount / pi.Quantity AS UnitCost
            FROM dbo.PurchaseItems pi
            INNER JOIN dbo.Purchase p ON p.PurchaseID = pi.PurchaseID
            WHERE pi.FruitID = @FruitID

            UNION ALL

            SELECT 'SHOP_RETURN' AS EventType, sri.ShopReturnItemID AS ItemID, sr.ReturnDate AS TransactionDate,
                   sr.CreatedAt AS ParentCreatedAt, sri.Quantity, sri.CostBasis AS UnitCost
            FROM dbo.ShopReturnItems sri
            INNER JOIN dbo.ShopReturns sr ON sr.ShopReturnID = sri.ShopReturnID
            WHERE sri.FruitID = @FruitID

            UNION ALL

            SELECT 'SUPPLY' AS EventType, si.SupplyItemID AS ItemID, s.SupplyDate AS TransactionDate,
                   s.CreatedAt AS ParentCreatedAt, si.Quantity, NULL AS UnitCost
            FROM dbo.SupplyItems si
            INNER JOIN dbo.Supply s ON s.SupplyID = si.SupplyID
            WHERE si.FruitID = @FruitID

            UNION ALL

            SELECT 'SUPPLIER_RETURN' AS EventType, sri2.SupplierReturnItemID AS ItemID, sr2.ReturnDate AS TransactionDate,
                   sr2.CreatedAt AS ParentCreatedAt, sri2.Quantity, NULL AS UnitCost
            FROM dbo.SupplierReturnItems sri2
            INNER JOIN dbo.SupplierReturns sr2 ON sr2.SupplierReturnID = sri2.SupplierReturnID
            WHERE sri2.FruitID = @FruitID

            ORDER BY TransactionDate ASC, ParentCreatedAt ASC, ItemID ASC;
            """;
        var events = await connection.QueryAsync<CostBasisEvent>(eventsSql, new { FruitID = fruitId }, transaction);

        var quantityOnHand = 0m;
        var averageCost = 0m;
        var supplyCostBasis = new Dictionary<int, decimal>();
        var supplierReturnCostBasis = new Dictionary<int, decimal>();

        foreach (var evt in events)
        {
            if (evt.EventType is "PURCHASE" or "SHOP_RETURN")
            {
                var newQuantity = quantityOnHand + evt.Quantity;
                // When on-hand is zero or negative (oversold - Supply/SupplierReturn allowed to
                // exceed stock elsewhere in the app), there's no real inventory value behind
                // quantityOnHand to blend: e.g. sell 10 with none in stock (quantityOnHand=-10,
                // averageCost=0), then buy 20 @ ₹5 - blending would compute
                // (-10*0 + 20*5)/10 = ₹10/unit instead of the ₹5 actually paid. Treat the
                // incoming UnitCost as the new average outright in that case.
                averageCost = quantityOnHand <= 0
                    ? evt.UnitCost ?? 0m
                    : newQuantity > 0
                        ? (quantityOnHand * averageCost + evt.Quantity * (evt.UnitCost ?? 0m)) / newQuantity
                        : 0m;
                quantityOnHand = newQuantity;
            }
            else if (evt.EventType == "SUPPLY")
            {
                supplyCostBasis[evt.ItemID] = averageCost;
                quantityOnHand -= evt.Quantity;
            }
            else // SUPPLIER_RETURN
            {
                supplierReturnCostBasis[evt.ItemID] = averageCost;
                quantityOnHand -= evt.Quantity;
            }
        }

        // Batched as a single set-based UPDATE per table (via OPENJSON) instead of one
        // round trip per changed row — a fruit's full transaction history can be large,
        // and this recalculation runs on every Purchase/Supply/Return write.
        await BatchUpdateCostBasisAsync(connection, transaction, "dbo.SupplyItems", "SupplyItemID", supplyCostBasis);
        await BatchUpdateCostBasisAsync(connection, transaction, "dbo.SupplierReturnItems", "SupplierReturnItemID", supplierReturnCostBasis);

        const string upsertSql = """
            UPDATE dbo.FruitCostBasis SET QuantityOnHand = @QuantityOnHand, AverageCost = @AverageCost, UpdatedAt = SYSUTCDATETIME()
            WHERE FruitID = @FruitID;

            IF @@ROWCOUNT = 0
                INSERT INTO dbo.FruitCostBasis (FruitID, QuantityOnHand, AverageCost, UpdatedAt)
                VALUES (@FruitID, @QuantityOnHand, @AverageCost, SYSUTCDATETIME());
            """;
        await connection.ExecuteAsync(upsertSql, new { FruitID = fruitId, QuantityOnHand = quantityOnHand, AverageCost = averageCost }, transaction);
    }

    /// <summary>
    /// Applies a {ItemID -&gt; CostBasis} map to a table in one round trip via OPENJSON,
    /// instead of one UPDATE per row. table/idColumn are always call-site literals
    /// (never user input), so interpolating them into the SQL text here is safe.
    /// </summary>
    private static async Task BatchUpdateCostBasisAsync(
        IDbConnection connection, IDbTransaction transaction, string table, string idColumn, IReadOnlyDictionary<int, decimal> costBasisByItemId)
    {
        if (costBasisByItemId.Count == 0)
        {
            return;
        }

        var json = JsonSerializer.Serialize(costBasisByItemId.Select(kvp => new { ItemID = kvp.Key, CostBasis = kvp.Value }));
        var sql = $"""
            UPDATE t SET t.CostBasis = j.CostBasis
            FROM {table} t
            INNER JOIN OPENJSON(@Json) WITH (ItemID INT '$.ItemID', CostBasis DECIMAL(18,4) '$.CostBasis') j
                ON j.ItemID = t.{idColumn};
            """;
        await connection.ExecuteAsync(sql, new { Json = json }, transaction);
    }

    private sealed class CostBasisEvent
    {
        public string EventType { get; set; } = string.Empty;
        public int ItemID { get; set; }
        public DateTime TransactionDate { get; set; }
        public DateTime ParentCreatedAt { get; set; }
        public decimal Quantity { get; set; }
        public decimal? UnitCost { get; set; }
    }

    public async Task<decimal> GetCurrentStockAsync(int fruitId)
    {
        using var connection = connectionFactory.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<decimal?>(
            "SELECT TOP 1 RunningStock FROM dbo.StockLedger WHERE FruitID = @FruitID ORDER BY TransactionDate DESC, StockLedgerID DESC",
            new { FruitID = fruitId }) ?? 0m;
    }

    public async Task<Dictionary<int, decimal>> GetCurrentStockForAllFruitsAsync()
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            SELECT sl.FruitID, sl.RunningStock
            FROM dbo.StockLedger sl
            INNER JOIN (
                SELECT FruitID, MAX(TransactionDate) AS MaxDate FROM dbo.StockLedger GROUP BY FruitID
            ) latestDate ON latestDate.FruitID = sl.FruitID AND latestDate.MaxDate = sl.TransactionDate
            INNER JOIN (
                SELECT FruitID, MAX(StockLedgerID) AS MaxID FROM dbo.StockLedger GROUP BY FruitID
            ) latestId ON latestId.FruitID = sl.FruitID AND latestId.MaxID = sl.StockLedgerID;
            """;
        var rows = await connection.QueryAsync<(int FruitID, decimal RunningStock)>(sql);
        return rows.ToDictionary(r => r.FruitID, r => r.RunningStock);
    }

    public async Task RecalculateFruitBoxesAsync(IDbConnection connection, IDbTransaction transaction, int fruitId)
    {
        var tracksByBox = await connection.ExecuteScalarAsync<bool>(
            "SELECT TracksByBox FROM dbo.FruitMaster WHERE FruitID = @FruitID", new { FruitID = fruitId }, transaction);

        await connection.ExecuteAsync("DELETE FROM dbo.FruitBoxes WHERE FruitID = @FruitID", new { FruitID = fruitId }, transaction);
        if (!tracksByBox) return;

        // Purchase (box-in) and Supply (kg-out) events, chronologically - same event-replay
        // approach as RecalculateFruitCostBasisAsync, so edits/deletes to either never need
        // manual box reconciliation, just a full replay. Shop Returns add stock back (a box-in
        // event, same shape as Purchase) and Supplier Returns remove stock (a kg-out event,
        // same shape as Supply) so they fold into the same two event types.
        const string eventsSql = """
            SELECT 'PURCHASE' AS EventType, pi.PurchaseItemID AS ItemID, p.PurchaseDate AS TransactionDate,
                   p.CreatedAt AS ParentCreatedAt, pi.Quantity, pi.BoxCount, p.PurchaseID
            FROM dbo.PurchaseItems pi
            INNER JOIN dbo.Purchase p ON p.PurchaseID = pi.PurchaseID
            WHERE pi.FruitID = @FruitID AND pi.BoxCount IS NOT NULL AND pi.BoxCount > 0

            UNION ALL

            SELECT 'SUPPLY' AS EventType, si.SupplyItemID AS ItemID, s.SupplyDate AS TransactionDate,
                   s.CreatedAt AS ParentCreatedAt, si.Quantity, NULL AS BoxCount, NULL AS PurchaseID
            FROM dbo.SupplyItems si
            INNER JOIN dbo.Supply s ON s.SupplyID = si.SupplyID
            WHERE si.FruitID = @FruitID

            UNION ALL

            SELECT 'PURCHASE' AS EventType, ri.ShopReturnItemID AS ItemID, r.ReturnDate AS TransactionDate,
                   r.CreatedAt AS ParentCreatedAt, ri.Quantity, ri.BoxCount, NULL AS PurchaseID
            FROM dbo.ShopReturnItems ri
            INNER JOIN dbo.ShopReturns r ON r.ShopReturnID = ri.ShopReturnID
            WHERE ri.FruitID = @FruitID AND ri.BoxCount IS NOT NULL AND ri.BoxCount > 0

            UNION ALL

            SELECT 'SUPPLY' AS EventType, ri.SupplierReturnItemID AS ItemID, r.ReturnDate AS TransactionDate,
                   r.CreatedAt AS ParentCreatedAt, ri.Quantity, NULL AS BoxCount, NULL AS PurchaseID
            FROM dbo.SupplierReturnItems ri
            INNER JOIN dbo.SupplierReturns r ON r.SupplierReturnID = ri.SupplierReturnID
            WHERE ri.FruitID = @FruitID

            ORDER BY TransactionDate ASC, ParentCreatedAt ASC, ItemID ASC;
            """;
        var events = await connection.QueryAsync<BoxEvent>(eventsSql, new { FruitID = fruitId }, transaction);

        var boxes = new List<BoxState>();
        foreach (var evt in events)
        {
            if (evt.EventType == "PURCHASE")
            {
                // BoxCount can be fractional (half a crate, etc.) - split into whole boxes at the
                // average weight plus one smaller box holding the exact remainder, so the sum of
                // box weights always matches Quantity exactly regardless of rounding.
                var perBoxWeight = evt.Quantity / evt.BoxCount!.Value;
                var fullBoxCount = (int)Math.Floor(evt.BoxCount.Value);
                for (var i = 0; i < fullBoxCount; i++)
                {
                    boxes.Add(new BoxState { InitialWeightKg = perBoxWeight, RemainingWeightKg = perBoxWeight, Status = FruitBoxStatuses.Full, PurchaseID = evt.PurchaseID });
                }
                var remainderWeight = evt.Quantity - (fullBoxCount * perBoxWeight);
                if (remainderWeight > 0)
                {
                    boxes.Add(new BoxState { InitialWeightKg = remainderWeight, RemainingWeightKg = remainderWeight, Status = FruitBoxStatuses.Full, PurchaseID = evt.PurchaseID });
                }
            }
            else // SUPPLY
            {
                var remaining = evt.Quantity;
                while (remaining > 0)
                {
                    var openBox = boxes.FirstOrDefault(b => b.Status == FruitBoxStatuses.Opened);
                    if (openBox is null)
                    {
                        openBox = boxes.FirstOrDefault(b => b.Status == FruitBoxStatuses.Full);
                        if (openBox is null) break; // selling more kg than tracked box inventory covers - stop silently, StockLedger kg is still correct
                        openBox.Status = FruitBoxStatuses.Opened;
                    }

                    var drain = Math.Min(remaining, openBox.RemainingWeightKg);
                    openBox.RemainingWeightKg -= drain;
                    remaining -= drain;
                    if (openBox.RemainingWeightKg <= 0)
                    {
                        openBox.RemainingWeightKg = 0;
                        openBox.Status = FruitBoxStatuses.Empty;
                    }
                }
            }
        }

        if (boxes.Count == 0) return;

        // Single set-based INSERT via OPENJSON instead of one round trip per box -
        // a box-tracked fruit's full replay can produce hundreds of rows per write.
        var json = JsonSerializer.Serialize(boxes.Select(b => new { b.PurchaseID, b.InitialWeightKg, b.RemainingWeightKg, b.Status }));
        const string insertSql = """
            INSERT INTO dbo.FruitBoxes (FruitID, PurchaseID, InitialWeightKg, RemainingWeightKg, Status)
            SELECT @FruitID, PurchaseID, InitialWeightKg, RemainingWeightKg, Status
            FROM OPENJSON(@Json) WITH (
                PurchaseID INT '$.PurchaseID',
                InitialWeightKg DECIMAL(18,4) '$.InitialWeightKg',
                RemainingWeightKg DECIMAL(18,4) '$.RemainingWeightKg',
                Status NVARCHAR(10) '$.Status'
            );
            """;
        await connection.ExecuteAsync(insertSql, new { FruitID = fruitId, Json = json }, transaction);
    }

    private sealed class BoxEvent
    {
        public string EventType { get; set; } = string.Empty;
        public int ItemID { get; set; }
        public DateTime TransactionDate { get; set; }
        public DateTime ParentCreatedAt { get; set; }
        public decimal Quantity { get; set; }
        public decimal? BoxCount { get; set; }
        public int? PurchaseID { get; set; }
    }

    private sealed class BoxState
    {
        public decimal InitialWeightKg { get; set; }
        public decimal RemainingWeightKg { get; set; }
        public string Status { get; set; } = string.Empty;
        public int? PurchaseID { get; set; }
    }

    public async Task<Dictionary<int, FruitBoxSummary>> GetCurrentBoxSummaryForAllFruitsAsync()
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            SELECT FruitID,
                   SUM(CASE WHEN Status = 'Full' THEN 1 ELSE 0 END) AS FullBoxCount,
                   MAX(CASE WHEN Status = 'Opened' THEN RemainingWeightKg END) AS OpenedBoxRemainingKg
            FROM dbo.FruitBoxes
            GROUP BY FruitID;
            """;
        var rows = await connection.QueryAsync<(int FruitID, int FullBoxCount, decimal? OpenedBoxRemainingKg)>(sql);
        return rows.ToDictionary(r => r.FruitID, r => new FruitBoxSummary { FullBoxCount = r.FullBoxCount, OpenedBoxRemainingKg = r.OpenedBoxRemainingKg });
    }

    public async Task<PaginatedLedger<StockLedger>> GetStockLedgerAsync(int fruitId, DateTime? fromDate, DateTime? toDate, int pageNumber, int pageSize)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            SELECT COUNT(*) FROM dbo.StockLedger
            WHERE FruitID = @FruitID
              AND (@FromDate IS NULL OR TransactionDate >= @FromDate)
              AND (@ToDate IS NULL OR TransactionDate < DATEADD(DAY, 1, @ToDate));

            SELECT * FROM dbo.StockLedger
            WHERE FruitID = @FruitID
              AND (@FromDate IS NULL OR TransactionDate >= @FromDate)
              AND (@ToDate IS NULL OR TransactionDate < DATEADD(DAY, 1, @ToDate))
            ORDER BY TransactionDate ASC, StockLedgerID ASC
            OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;
            """;
        using var multi = await connection.QueryMultipleAsync(sql, new
        {
            FruitID = fruitId,
            FromDate = fromDate,
            ToDate = toDate,
            Offset = (pageNumber - 1) * pageSize,
            PageSize = pageSize
        });
        var total = await multi.ReadSingleAsync<int>();
        var items = (await multi.ReadAsync<StockLedger>()).ToList();
        return new PaginatedLedger<StockLedger> { Items = items, TotalCount = total };
    }
}
