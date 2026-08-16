using Dapper;
using FruitWholesale.Application.Common.Interfaces;
using FruitWholesale.Domain.Entities;
using FruitWholesale.Domain.Enums;
using FruitWholesale.Shared.Pagination;

namespace FruitWholesale.Infrastructure.Repositories;

public class PurchaseRepository(IDbConnectionFactory connectionFactory, ILedgerService ledgerService) : IPurchaseRepository
{
    public async Task<Purchase?> GetByIdAsync(int purchaseId)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            SELECT p.*, sp.SupplierName FROM Purchase p
            INNER JOIN SupplierMaster sp ON sp.SupplierID = p.SupplierID
            WHERE p.PurchaseID = @PurchaseID;

            SELECT pi.*, f.FruitName, f.Unit FROM PurchaseItems pi
            INNER JOIN FruitMaster f ON f.FruitID = pi.FruitID
            WHERE pi.PurchaseID = @PurchaseID;
            """;
        using var multi = await connection.QueryMultipleAsync(sql, new { PurchaseID = purchaseId });
        var purchase = await multi.ReadFirstOrDefaultAsync<Purchase>();
        if (purchase is null) return null;
        purchase.Items = (await multi.ReadAsync<PurchaseItem>()).ToList();
        return purchase;
    }

    public async Task<PaginatedList<Purchase>> GetPagedAsync(PaginationRequest request, int? supplierId, DateTime? fromDate, DateTime? toDate)
    {
        using var connection = connectionFactory.CreateConnection();
        const string sql = """
            SELECT COUNT(*) FROM Purchase p
            INNER JOIN SupplierMaster sp ON sp.SupplierID = p.SupplierID
            WHERE (@SupplierID::int IS NULL OR p.SupplierID = @SupplierID)
              AND (@FromDate::date IS NULL OR p.PurchaseDate >= @FromDate)
              AND (@ToDate::date IS NULL OR p.PurchaseDate <= @ToDate)
              AND (@SearchTerm::text IS NULL OR p.InvoiceNo ILIKE @SearchPattern OR sp.SupplierName ILIKE @SearchPattern);

            SELECT p.*, sp.SupplierName FROM Purchase p
            INNER JOIN SupplierMaster sp ON sp.SupplierID = p.SupplierID
            WHERE (@SupplierID::int IS NULL OR p.SupplierID = @SupplierID)
              AND (@FromDate::date IS NULL OR p.PurchaseDate >= @FromDate)
              AND (@ToDate::date IS NULL OR p.PurchaseDate <= @ToDate)
              AND (@SearchTerm::text IS NULL OR p.InvoiceNo ILIKE @SearchPattern OR sp.SupplierName ILIKE @SearchPattern)
            ORDER BY p.PurchaseDate DESC, p.PurchaseID DESC
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
        var items = (await multi.ReadAsync<Purchase>()).ToList();
        return new PaginatedList<Purchase>(items, total, request.PageNumber, request.PageSize);
    }

    public async Task<int> CreateAsync(Purchase purchase)
    {
        using var connection = connectionFactory.CreateConnection();
        connection.Open();
        using var transaction = connection.BeginTransaction();
        try
        {
            purchase.TotalAmount = purchase.Items.Sum(i => i.TotalAmount);

            const string insertSql = """
                INSERT INTO Purchase (PurchaseDate, SupplierID, InvoiceNo, Remarks, TotalAmount, CreatedBy)
                VALUES (@PurchaseDate, @SupplierID, @InvoiceNo, @Remarks, @TotalAmount, @CreatedBy)
                RETURNING PurchaseID;
                """;
            var purchaseId = await connection.QuerySingleAsync<int>(insertSql, purchase, transaction);

            const string insertItemSql = """
                INSERT INTO PurchaseItems (PurchaseID, FruitID, Quantity, PurchasePrice, TotalAmount, BoxCount)
                VALUES (@PurchaseID, @FruitID, @Quantity, @PurchasePrice, @TotalAmount, @BoxCount);
                """;
            foreach (var item in purchase.Items)
            {
                item.PurchaseID = purchaseId;
                await connection.ExecuteAsync(insertItemSql, item, transaction);
            }

            await ledgerService.AddSupplierLedgerEntryAsync(connection, transaction, purchase.SupplierID, purchase.PurchaseDate,
                LedgerTransactionTypes.Purchase, purchaseId, purchase.TotalAmount, 0, $"Purchase Invoice #{purchase.InvoiceNo}");
            await ledgerService.RecalculateSupplierLedgerAsync(connection, transaction, purchase.SupplierID);

            foreach (var item in purchase.Items)
            {
                await ledgerService.AddStockLedgerEntryAsync(connection, transaction, item.FruitID, purchase.PurchaseDate,
                    LedgerTransactionTypes.Purchase, ReferenceTables.Purchase, purchaseId, item.Quantity, 0, $"Purchase Invoice #{purchase.InvoiceNo}");
            }
            foreach (var fruitId in purchase.Items.Select(i => i.FruitID).Distinct())
            {
                await ledgerService.RecalculateStockLedgerAsync(connection, transaction, fruitId);
                await ledgerService.RecalculateFruitCostBasisAsync(connection, transaction, fruitId);
                await ledgerService.RecalculateFruitBoxesAsync(connection, transaction, fruitId);
            }

            transaction.Commit();
            return purchaseId;
        }
        catch
        {
            transaction.Rollback();
            throw;
        }
    }

    public async Task UpdateAsync(Purchase purchase)
    {
        using var connection = connectionFactory.CreateConnection();
        connection.Open();
        using var transaction = connection.BeginTransaction();
        try
        {
            var oldSupplierId = await connection.ExecuteScalarAsync<int>(
                "SELECT SupplierID FROM Purchase WHERE PurchaseID = @PurchaseID", new { purchase.PurchaseID }, transaction);
            var oldFruitIds = (await connection.QueryAsync<int>(
                "SELECT DISTINCT FruitID FROM PurchaseItems WHERE PurchaseID = @PurchaseID", new { purchase.PurchaseID }, transaction)).ToList();

            purchase.TotalAmount = purchase.Items.Sum(i => i.TotalAmount);

            const string updateSql = """
                UPDATE Purchase
                SET PurchaseDate = @PurchaseDate, SupplierID = @SupplierID, InvoiceNo = @InvoiceNo,
                    Remarks = @Remarks, TotalAmount = @TotalAmount, UpdatedAt = (now() AT TIME ZONE 'utc')
                WHERE PurchaseID = @PurchaseID;
                """;
            await connection.ExecuteAsync(updateSql, purchase, transaction);

            await connection.ExecuteAsync("DELETE FROM PurchaseItems WHERE PurchaseID = @PurchaseID", new { purchase.PurchaseID }, transaction);

            const string insertItemSql = """
                INSERT INTO PurchaseItems (PurchaseID, FruitID, Quantity, PurchasePrice, TotalAmount, BoxCount)
                VALUES (@PurchaseID, @FruitID, @Quantity, @PurchasePrice, @TotalAmount, @BoxCount);
                """;
            foreach (var item in purchase.Items)
            {
                item.PurchaseID = purchase.PurchaseID;
                await connection.ExecuteAsync(insertItemSql, item, transaction);
            }

            await ledgerService.RemoveSupplierLedgerEntriesForReferenceAsync(connection, transaction, LedgerTransactionTypes.Purchase, purchase.PurchaseID);
            await ledgerService.AddSupplierLedgerEntryAsync(connection, transaction, purchase.SupplierID, purchase.PurchaseDate,
                LedgerTransactionTypes.Purchase, purchase.PurchaseID, purchase.TotalAmount, 0, $"Purchase Invoice #{purchase.InvoiceNo}");

            await ledgerService.RecalculateSupplierLedgerAsync(connection, transaction, purchase.SupplierID);
            if (oldSupplierId != purchase.SupplierID)
            {
                await ledgerService.RecalculateSupplierLedgerAsync(connection, transaction, oldSupplierId);
            }

            await ledgerService.RemoveStockLedgerEntriesForReferenceAsync(connection, transaction, ReferenceTables.Purchase, purchase.PurchaseID);
            foreach (var item in purchase.Items)
            {
                await ledgerService.AddStockLedgerEntryAsync(connection, transaction, item.FruitID, purchase.PurchaseDate,
                    LedgerTransactionTypes.Purchase, ReferenceTables.Purchase, purchase.PurchaseID, item.Quantity, 0, $"Purchase Invoice #{purchase.InvoiceNo}");
            }
            var newFruitIds = purchase.Items.Select(i => i.FruitID).Distinct();
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

    public async Task DeleteAsync(int purchaseId)
    {
        using var connection = connectionFactory.CreateConnection();
        connection.Open();
        using var transaction = connection.BeginTransaction();
        try
        {
            var supplierId = await connection.ExecuteScalarAsync<int>(
                "SELECT SupplierID FROM Purchase WHERE PurchaseID = @PurchaseID", new { PurchaseID = purchaseId }, transaction);
            var fruitIds = (await connection.QueryAsync<int>(
                "SELECT DISTINCT FruitID FROM PurchaseItems WHERE PurchaseID = @PurchaseID", new { PurchaseID = purchaseId }, transaction)).ToList();

            await ledgerService.RemoveSupplierLedgerEntriesForReferenceAsync(connection, transaction, LedgerTransactionTypes.Purchase, purchaseId);
            await ledgerService.RemoveStockLedgerEntriesForReferenceAsync(connection, transaction, ReferenceTables.Purchase, purchaseId);
            await connection.ExecuteAsync("DELETE FROM Purchase WHERE PurchaseID = @PurchaseID", new { PurchaseID = purchaseId }, transaction);
            await ledgerService.RecalculateSupplierLedgerAsync(connection, transaction, supplierId);
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

    public async Task<bool> InvoiceNoExistsAsync(string invoiceNo, int? excludePurchaseId = null)
    {
        using var connection = connectionFactory.CreateConnection();
        return await connection.ExecuteScalarAsync<bool>(
            "SELECT EXISTS (SELECT 1 FROM Purchase WHERE InvoiceNo = @InvoiceNo AND (@ExcludePurchaseId::int IS NULL OR PurchaseID <> @ExcludePurchaseId))",
            new { InvoiceNo = invoiceNo, ExcludePurchaseId = excludePurchaseId });
    }

    public async Task<string> GenerateNextInvoiceNoAsync()
    {
        using var connection = connectionFactory.CreateConnection();
        var maxSeq = await connection.ExecuteScalarAsync<int?>("""
            SELECT MAX(CASE WHEN SUBSTRING(InvoiceNo FROM 4) ~ '^[0-9]+$' THEN CAST(SUBSTRING(InvoiceNo FROM 4) AS INT) ELSE NULL END)
            FROM Purchase
            WHERE InvoiceNo LIKE 'PUR%'
            """);
        return $"PUR{(maxSeq ?? 0) + 1:D6}";
    }
}
