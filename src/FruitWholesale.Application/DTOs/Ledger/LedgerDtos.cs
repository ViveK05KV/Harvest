namespace FruitWholesale.Application.DTOs.Ledger;

public class ShopLedgerDto
{
    public long LedgerID { get; set; }
    public DateTime TransactionDate { get; set; }
    public string TransactionType { get; set; } = string.Empty;
    public int? ReferenceID { get; set; }
    public decimal Debit { get; set; }
    public decimal Credit { get; set; }
    public decimal RunningBalance { get; set; }
    public string? Narration { get; set; }
}

public class SupplierLedgerDto
{
    public long LedgerID { get; set; }
    public DateTime TransactionDate { get; set; }
    public string TransactionType { get; set; } = string.Empty;
    public int? ReferenceID { get; set; }
    public decimal Debit { get; set; }
    public decimal Credit { get; set; }
    public decimal RunningBalance { get; set; }
    public string? Narration { get; set; }
}

public class CashLedgerDto
{
    public long CashLedgerID { get; set; }
    public DateTime TransactionDate { get; set; }
    public string TransactionType { get; set; } = string.Empty;
    public string ReferenceTable { get; set; } = string.Empty;
    public int? ReferenceID { get; set; }
    public string PaymentMode { get; set; } = string.Empty;
    public decimal CashIn { get; set; }
    public decimal CashOut { get; set; }
    public decimal RunningBalance { get; set; }
    public string? Narration { get; set; }
}
