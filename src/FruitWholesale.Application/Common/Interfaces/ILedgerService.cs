using System.Data;
using FruitWholesale.Domain.Entities;

namespace FruitWholesale.Application.Common.Interfaces;

/// <summary>
/// Encapsulates the business rules that keep ShopLedger, SupplierLedger and
/// CashLedger synchronized with every transaction that affects them. All
/// methods participate in the caller's ambient connection/transaction so
/// that the ledger write and the source-document write commit atomically.
/// </summary>
public interface ILedgerService
{
    Task<decimal> AddShopLedgerEntryAsync(IDbConnection connection, IDbTransaction transaction, int shopId,
        DateTime transactionDate, string transactionType, int? referenceId, decimal debit, decimal credit, string narration);

    Task<decimal> AddSupplierLedgerEntryAsync(IDbConnection connection, IDbTransaction transaction, int supplierId,
        DateTime transactionDate, string transactionType, int? referenceId, decimal debit, decimal credit, string narration);

    Task<decimal> AddCashLedgerEntryAsync(IDbConnection connection, IDbTransaction transaction,
        DateTime transactionDate, string transactionType, string referenceTable, int? referenceId,
        string paymentMode, decimal cashIn, decimal cashOut, string narration);

    Task RemoveShopLedgerEntriesForReferenceAsync(IDbConnection connection, IDbTransaction transaction, string transactionType, int referenceId);

    Task RemoveSupplierLedgerEntriesForReferenceAsync(IDbConnection connection, IDbTransaction transaction, string transactionType, int referenceId);

    Task RemoveCashLedgerEntriesForReferenceAsync(IDbConnection connection, IDbTransaction transaction, string referenceTable, int referenceId);

    /// <summary>Deletes a single Adjustment-type ShopLedger row. Refuses to delete any other TransactionType. Returns the affected row count.</summary>
    Task<int> DeleteShopLedgerAdjustmentAsync(IDbConnection connection, IDbTransaction transaction, int shopId, long ledgerId);

    /// <summary>Deletes a single Adjustment-type SupplierLedger row. Refuses to delete any other TransactionType. Returns the affected row count.</summary>
    Task<int> DeleteSupplierLedgerAdjustmentAsync(IDbConnection connection, IDbTransaction transaction, int supplierId, long ledgerId);

    Task RecalculateShopLedgerAsync(IDbConnection connection, IDbTransaction transaction, int shopId);

    Task RecalculateSupplierLedgerAsync(IDbConnection connection, IDbTransaction transaction, int supplierId);

    Task RecalculateCashLedgerAsync(IDbConnection connection, IDbTransaction transaction);

    Task<decimal> GetShopOutstandingAsync(int shopId);

    Task<Dictionary<int, decimal>> GetShopOutstandingBatchAsync(IEnumerable<int> shopIds);

    Task<decimal> GetSupplierOutstandingAsync(int supplierId);

    Task<Dictionary<int, decimal>> GetSupplierOutstandingBatchAsync(IEnumerable<int> supplierIds);

    Task<PaginatedLedger<ShopLedger>> GetShopLedgerAsync(int shopId, DateTime? fromDate, DateTime? toDate, int pageNumber, int pageSize);

    Task<PaginatedLedger<SupplierLedger>> GetSupplierLedgerAsync(int supplierId, DateTime? fromDate, DateTime? toDate, int pageNumber, int pageSize);

    Task<PaginatedLedger<CashLedger>> GetCashLedgerAsync(DateTime? fromDate, DateTime? toDate, string? transactionType, bool newestFirst, int pageNumber, int pageSize);

    /// <summary>The RunningBalance on the chronologically latest CashLedger row - the company's current cash on hand, unaffected by any list filter.</summary>
    Task<decimal> GetCurrentCashBalanceAsync();

    Task<decimal> AddStockLedgerEntryAsync(IDbConnection connection, IDbTransaction transaction, int fruitId,
        DateTime transactionDate, string transactionType, string referenceTable, int? referenceId,
        decimal quantityIn, decimal quantityOut, string narration);

    Task RemoveStockLedgerEntriesForReferenceAsync(IDbConnection connection, IDbTransaction transaction, string referenceTable, int referenceId);

    Task RecalculateStockLedgerAsync(IDbConnection connection, IDbTransaction transaction, int fruitId);

    /// <summary>
    /// Walks a fruit's full Purchase/Supply/ShopReturn/SupplierReturn history in date
    /// order to recompute its FIFO cost (oldest stock sold first), snapshotting the cost
    /// of what was actually drawn onto every SupplyItems/SupplierReturnItems row it
    /// passes, and rebuilding FruitCostLayers/FruitCostBasis with the current remaining
    /// state (see database/30_SwitchToFifoCostBasis.sql for the rationale).
    /// </summary>
    Task RecalculateFruitCostBasisAsync(IDbConnection connection, IDbTransaction transaction, int fruitId);

    /// <summary>One-time maintenance sweep: recalculates FIFO cost basis for every fruit.
    /// Safe to re-run.</summary>
    Task RecalculateAllFruitCostBasisAsync();

    Task<decimal> GetCurrentStockAsync(int fruitId);

    Task<Dictionary<int, decimal>> GetCurrentStockForAllFruitsAsync();

    /// <summary>
    /// Rebuilds a TracksByBox fruit's FruitBoxes from scratch by replaying its
    /// Purchase (box-in) and Supply (kg-out) history in chronological order - same
    /// approach as RecalculateFruitCostBasisAsync. No-ops (and clears any stray rows)
    /// for fruits that aren't TracksByBox. Call after any Purchase/Supply write.
    /// </summary>
    Task RecalculateFruitBoxesAsync(IDbConnection connection, IDbTransaction transaction, int fruitId);

    Task<Dictionary<int, FruitBoxSummary>> GetCurrentBoxSummaryForAllFruitsAsync();

    Task<PaginatedLedger<StockLedger>> GetStockLedgerAsync(int fruitId, DateTime? fromDate, DateTime? toDate, int pageNumber, int pageSize);
}

public class PaginatedLedger<T>
{
    public IReadOnlyList<T> Items { get; init; } = [];
    public int TotalCount { get; init; }
}

public class FruitBoxSummary
{
    public int FullBoxCount { get; init; }
    public decimal? OpenedBoxRemainingKg { get; init; }
}
