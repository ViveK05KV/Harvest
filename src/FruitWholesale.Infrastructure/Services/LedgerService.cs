using System.Data;
using Dapper;
using FruitWholesale.Application.Common.Interfaces;
using FruitWholesale.Domain.Entities;

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
        return await connection.QueryFirstOrDefaultAsync<decimal?>(
            "SELECT TOP 1 RunningBalance FROM dbo.ShopLedger WHERE ShopID = @ShopID ORDER BY TransactionDate DESC, LedgerID DESC",
            new { ShopID = shopId }) ?? 0m;
    }

    public async Task<decimal> GetSupplierOutstandingAsync(int supplierId)
    {
        using var connection = connectionFactory.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<decimal?>(
            "SELECT TOP 1 RunningBalance FROM dbo.SupplierLedger WHERE SupplierID = @SupplierID ORDER BY TransactionDate DESC, LedgerID DESC",
            new { SupplierID = supplierId }) ?? 0m;
    }

    public async Task<decimal> GetCurrentCashBalanceAsync()
    {
        using var connection = connectionFactory.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<decimal?>(
            "SELECT TOP 1 RunningBalance FROM dbo.CashLedger ORDER BY TransactionDate DESC, CashLedgerID DESC") ?? 0m;
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

    public async Task<PaginatedLedger<CashLedger>> GetCashLedgerAsync(DateTime? fromDate, DateTime? toDate, int pageNumber, int pageSize)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            SELECT COUNT(*) FROM dbo.CashLedger
            WHERE (@FromDate IS NULL OR TransactionDate >= @FromDate)
              AND (@ToDate IS NULL OR TransactionDate < DATEADD(DAY, 1, @ToDate));

            SELECT * FROM dbo.CashLedger
            WHERE (@FromDate IS NULL OR TransactionDate >= @FromDate)
              AND (@ToDate IS NULL OR TransactionDate < DATEADD(DAY, 1, @ToDate))
            ORDER BY TransactionDate ASC, CashLedgerID ASC
            OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;
            """;
        using var multi = await connection.QueryMultipleAsync(sql, new
        {
            FromDate = fromDate,
            ToDate = toDate,
            Offset = (pageNumber - 1) * pageSize,
            PageSize = pageSize
        });
        var total = await multi.ReadSingleAsync<int>();
        var items = (await multi.ReadAsync<CashLedger>()).ToList();
        return new PaginatedLedger<CashLedger> { Items = items, TotalCount = total };
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
