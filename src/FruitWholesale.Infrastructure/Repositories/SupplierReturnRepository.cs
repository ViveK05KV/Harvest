using Dapper;
using FruitWholesale.Application.Common.Interfaces;
using FruitWholesale.Domain.Entities;
using FruitWholesale.Domain.Enums;
using FruitWholesale.Shared.Pagination;

namespace FruitWholesale.Infrastructure.Repositories;

public class SupplierReturnRepository(IDbConnectionFactory connectionFactory, ILedgerService ledgerService) : ISupplierReturnRepository
{
    public async Task<SupplierReturn?> GetByIdAsync(int supplierReturnId)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            SELECT r.*, sp.SupplierName, p.InvoiceNo AS PurchaseInvoiceNo FROM dbo.SupplierReturns r
            INNER JOIN dbo.SupplierMaster sp ON sp.SupplierID = r.SupplierID
            LEFT JOIN dbo.Purchase p ON p.PurchaseID = r.PurchaseID
            WHERE r.SupplierReturnID = @SupplierReturnID;

            SELECT ri.*, f.FruitName, f.Unit FROM dbo.SupplierReturnItems ri
            INNER JOIN dbo.FruitMaster f ON f.FruitID = ri.FruitID
            WHERE ri.SupplierReturnID = @SupplierReturnID;
            """;
        using var multi = await connection.QueryMultipleAsync(sql, new { SupplierReturnID = supplierReturnId });
        var supplierReturn = await multi.ReadFirstOrDefaultAsync<SupplierReturn>();
        if (supplierReturn is null) return null;
        supplierReturn.Items = (await multi.ReadAsync<SupplierReturnItem>()).ToList();
        return supplierReturn;
    }

    public async Task<PaginatedList<SupplierReturn>> GetPagedAsync(PaginationRequest request, int? supplierId, DateTime? fromDate, DateTime? toDate)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            SELECT COUNT(*) FROM dbo.SupplierReturns r
            INNER JOIN dbo.SupplierMaster sp ON sp.SupplierID = r.SupplierID
            WHERE (@SupplierID IS NULL OR r.SupplierID = @SupplierID)
              AND (@FromDate IS NULL OR r.ReturnDate >= @FromDate)
              AND (@ToDate IS NULL OR r.ReturnDate <= @ToDate)
              AND (@SearchTerm IS NULL OR r.ReferenceNo LIKE @SearchPattern OR sp.SupplierName LIKE @SearchPattern);

            SELECT r.*, sp.SupplierName, p.InvoiceNo AS PurchaseInvoiceNo FROM dbo.SupplierReturns r
            INNER JOIN dbo.SupplierMaster sp ON sp.SupplierID = r.SupplierID
            LEFT JOIN dbo.Purchase p ON p.PurchaseID = r.PurchaseID
            WHERE (@SupplierID IS NULL OR r.SupplierID = @SupplierID)
              AND (@FromDate IS NULL OR r.ReturnDate >= @FromDate)
              AND (@ToDate IS NULL OR r.ReturnDate <= @ToDate)
              AND (@SearchTerm IS NULL OR r.ReferenceNo LIKE @SearchPattern OR sp.SupplierName LIKE @SearchPattern)
            ORDER BY r.ReturnDate DESC, r.SupplierReturnID DESC
            OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;
            """;
        using var multi = await connection.QueryMultipleAsync(sql, new
        {
            SupplierID = supplierId,
            FromDate = fromDate,
            ToDate = toDate,
            SearchTerm = request.SearchTerm,
            SearchPattern = $"%{request.SearchTerm}%",
            request.Offset,
            request.PageSize
        });
        var total = await multi.ReadSingleAsync<int>();
        var items = (await multi.ReadAsync<SupplierReturn>()).ToList();
        return new PaginatedList<SupplierReturn>(items, total, request.PageNumber, request.PageSize);
    }

    public async Task<int> CreateAsync(SupplierReturn supplierReturn)
    {
        using var connection = connectionFactory.CreateConnection();
        connection.Open();
        using var transaction = connection.BeginTransaction();
        try
        {
            supplierReturn.TotalAmount = supplierReturn.Items.Sum(i => i.TotalAmount);

            const string insertSql = """
                INSERT INTO dbo.SupplierReturns (ReturnDate, SupplierID, PurchaseID, ReferenceNo, Remarks, TotalAmount, CreatedBy)
                OUTPUT INSERTED.SupplierReturnID
                VALUES (@ReturnDate, @SupplierID, @PurchaseID, @ReferenceNo, @Remarks, @TotalAmount, @CreatedBy);
                """;
            var supplierReturnId = await connection.QuerySingleAsync<int>(insertSql, supplierReturn, transaction);

            const string insertItemSql = """
                INSERT INTO dbo.SupplierReturnItems (SupplierReturnID, FruitID, Quantity, UnitPrice, TotalAmount)
                VALUES (@SupplierReturnID, @FruitID, @Quantity, @UnitPrice, @TotalAmount);
                """;
            foreach (var item in supplierReturn.Items)
            {
                item.SupplierReturnID = supplierReturnId;
                await connection.ExecuteAsync(insertItemSql, item, transaction);
            }

            await ledgerService.AddSupplierLedgerEntryAsync(connection, transaction, supplierReturn.SupplierID, supplierReturn.ReturnDate,
                LedgerTransactionTypes.SupplierReturn, supplierReturnId, 0, supplierReturn.TotalAmount, $"Supplier Return #{supplierReturn.ReferenceNo}");
            await ledgerService.RecalculateSupplierLedgerAsync(connection, transaction, supplierReturn.SupplierID);

            foreach (var item in supplierReturn.Items)
            {
                await ledgerService.AddStockLedgerEntryAsync(connection, transaction, item.FruitID, supplierReturn.ReturnDate,
                    LedgerTransactionTypes.SupplierReturn, ReferenceTables.SupplierReturns, supplierReturnId, 0, item.Quantity, $"Supplier Return #{supplierReturn.ReferenceNo}");
            }
            foreach (var fruitId in supplierReturn.Items.Select(i => i.FruitID).Distinct())
            {
                await ledgerService.RecalculateStockLedgerAsync(connection, transaction, fruitId);
                await ledgerService.RecalculateFruitCostBasisAsync(connection, transaction, fruitId);
            }

            transaction.Commit();
            return supplierReturnId;
        }
        catch
        {
            transaction.Rollback();
            throw;
        }
    }

    public async Task UpdateAsync(SupplierReturn supplierReturn)
    {
        using var connection = connectionFactory.CreateConnection();
        connection.Open();
        using var transaction = connection.BeginTransaction();
        try
        {
            var oldSupplierId = await connection.ExecuteScalarAsync<int>(
                "SELECT SupplierID FROM dbo.SupplierReturns WHERE SupplierReturnID = @SupplierReturnID", new { supplierReturn.SupplierReturnID }, transaction);
            var oldFruitIds = (await connection.QueryAsync<int>(
                "SELECT DISTINCT FruitID FROM dbo.SupplierReturnItems WHERE SupplierReturnID = @SupplierReturnID", new { supplierReturn.SupplierReturnID }, transaction)).ToList();

            supplierReturn.TotalAmount = supplierReturn.Items.Sum(i => i.TotalAmount);

            const string updateSql = """
                UPDATE dbo.SupplierReturns
                SET ReturnDate = @ReturnDate, SupplierID = @SupplierID, PurchaseID = @PurchaseID, ReferenceNo = @ReferenceNo,
                    Remarks = @Remarks, TotalAmount = @TotalAmount, UpdatedAt = SYSUTCDATETIME()
                WHERE SupplierReturnID = @SupplierReturnID;
                """;
            await connection.ExecuteAsync(updateSql, supplierReturn, transaction);

            await connection.ExecuteAsync("DELETE FROM dbo.SupplierReturnItems WHERE SupplierReturnID = @SupplierReturnID", new { supplierReturn.SupplierReturnID }, transaction);

            const string insertItemSql = """
                INSERT INTO dbo.SupplierReturnItems (SupplierReturnID, FruitID, Quantity, UnitPrice, TotalAmount)
                VALUES (@SupplierReturnID, @FruitID, @Quantity, @UnitPrice, @TotalAmount);
                """;
            foreach (var item in supplierReturn.Items)
            {
                item.SupplierReturnID = supplierReturn.SupplierReturnID;
                await connection.ExecuteAsync(insertItemSql, item, transaction);
            }

            await ledgerService.RemoveSupplierLedgerEntriesForReferenceAsync(connection, transaction, LedgerTransactionTypes.SupplierReturn, supplierReturn.SupplierReturnID);
            await ledgerService.AddSupplierLedgerEntryAsync(connection, transaction, supplierReturn.SupplierID, supplierReturn.ReturnDate,
                LedgerTransactionTypes.SupplierReturn, supplierReturn.SupplierReturnID, 0, supplierReturn.TotalAmount, $"Supplier Return #{supplierReturn.ReferenceNo}");

            await ledgerService.RecalculateSupplierLedgerAsync(connection, transaction, supplierReturn.SupplierID);
            if (oldSupplierId != supplierReturn.SupplierID)
            {
                await ledgerService.RecalculateSupplierLedgerAsync(connection, transaction, oldSupplierId);
            }

            await ledgerService.RemoveStockLedgerEntriesForReferenceAsync(connection, transaction, ReferenceTables.SupplierReturns, supplierReturn.SupplierReturnID);
            foreach (var item in supplierReturn.Items)
            {
                await ledgerService.AddStockLedgerEntryAsync(connection, transaction, item.FruitID, supplierReturn.ReturnDate,
                    LedgerTransactionTypes.SupplierReturn, ReferenceTables.SupplierReturns, supplierReturn.SupplierReturnID, 0, item.Quantity, $"Supplier Return #{supplierReturn.ReferenceNo}");
            }
            var newFruitIds = supplierReturn.Items.Select(i => i.FruitID).Distinct();
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

    public async Task DeleteAsync(int supplierReturnId)
    {
        using var connection = connectionFactory.CreateConnection();
        connection.Open();
        using var transaction = connection.BeginTransaction();
        try
        {
            var supplierId = await connection.ExecuteScalarAsync<int>(
                "SELECT SupplierID FROM dbo.SupplierReturns WHERE SupplierReturnID = @SupplierReturnID", new { SupplierReturnID = supplierReturnId }, transaction);
            var fruitIds = (await connection.QueryAsync<int>(
                "SELECT DISTINCT FruitID FROM dbo.SupplierReturnItems WHERE SupplierReturnID = @SupplierReturnID", new { SupplierReturnID = supplierReturnId }, transaction)).ToList();

            await ledgerService.RemoveSupplierLedgerEntriesForReferenceAsync(connection, transaction, LedgerTransactionTypes.SupplierReturn, supplierReturnId);
            await ledgerService.RemoveStockLedgerEntriesForReferenceAsync(connection, transaction, ReferenceTables.SupplierReturns, supplierReturnId);
            await connection.ExecuteAsync("DELETE FROM dbo.SupplierReturns WHERE SupplierReturnID = @SupplierReturnID", new { SupplierReturnID = supplierReturnId }, transaction);
            await ledgerService.RecalculateSupplierLedgerAsync(connection, transaction, supplierId);
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

    public async Task<bool> ReferenceNoExistsAsync(string referenceNo, int? excludeSupplierReturnId = null)
    {
        using var connection = connectionFactory.CreateConnection();
        return await connection.ExecuteScalarAsync<bool>(
            "SELECT CASE WHEN EXISTS (SELECT 1 FROM dbo.SupplierReturns WHERE ReferenceNo = @ReferenceNo AND (@ExcludeSupplierReturnId IS NULL OR SupplierReturnID <> @ExcludeSupplierReturnId)) THEN 1 ELSE 0 END",
            new { ReferenceNo = referenceNo, ExcludeSupplierReturnId = excludeSupplierReturnId });
    }

    public async Task<string> GenerateNextReferenceNoAsync()
    {
        using var connection = connectionFactory.CreateConnection();
        var maxSeq = await connection.ExecuteScalarAsync<int?>("""
            SELECT MAX(TRY_CAST(SUBSTRING(ReferenceNo, 4, 20) AS INT))
            FROM dbo.SupplierReturns
            WHERE ReferenceNo LIKE 'PRT%'
            """);
        return $"PRT{(maxSeq ?? 0) + 1:D6}";
    }
}
