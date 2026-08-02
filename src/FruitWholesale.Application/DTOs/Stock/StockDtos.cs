namespace FruitWholesale.Application.DTOs.Stock;

public class CurrentStockDto
{
    public int FruitID { get; set; }
    public string FruitName { get; set; } = string.Empty;
    public string Unit { get; set; } = string.Empty;
    public decimal CurrentStock { get; set; }

    // Only meaningful when TracksByBox is true - see database/18_AddFruitBoxTracking.sql.
    public bool TracksByBox { get; set; }
    public int FullBoxCount { get; set; }
    public decimal? OpenedBoxRemainingKg { get; set; }
}

public class StockLedgerDto
{
    public long StockLedgerID { get; set; }
    public DateTime TransactionDate { get; set; }
    public string TransactionType { get; set; } = string.Empty;
    public int? ReferenceID { get; set; }
    public decimal QuantityIn { get; set; }
    public decimal QuantityOut { get; set; }
    public decimal RunningStock { get; set; }
    public string? Narration { get; set; }
}

public class StockAdjustmentDto
{
    public int FruitID { get; set; }
    public decimal Quantity { get; set; }
    public bool IsIncrease { get; set; }
    public string Narration { get; set; } = string.Empty;
}
