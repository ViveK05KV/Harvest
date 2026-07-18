namespace FruitWholesale.Domain.Entities;

public class SupplierLedger
{
    public long LedgerID { get; set; }
    public int SupplierID { get; set; }
    public DateTime TransactionDate { get; set; }
    public string TransactionType { get; set; } = string.Empty;
    public int? ReferenceID { get; set; }
    public decimal Debit { get; set; }
    public decimal Credit { get; set; }
    public decimal RunningBalance { get; set; }
    public string? Narration { get; set; }
    public DateTime CreatedAt { get; set; }

    public string? SupplierName { get; set; }
}
