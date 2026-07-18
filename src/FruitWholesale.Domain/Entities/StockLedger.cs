namespace FruitWholesale.Domain.Entities;

public class StockLedger
{
    public long StockLedgerID { get; set; }
    public int FruitID { get; set; }
    public DateTime TransactionDate { get; set; }
    public string TransactionType { get; set; } = string.Empty;
    public string ReferenceTable { get; set; } = string.Empty;
    public int? ReferenceID { get; set; }
    public decimal QuantityIn { get; set; }
    public decimal QuantityOut { get; set; }
    public decimal RunningStock { get; set; }
    public string? Narration { get; set; }
    public DateTime CreatedAt { get; set; }

    public string? FruitName { get; set; }
    public string? Unit { get; set; }
}
