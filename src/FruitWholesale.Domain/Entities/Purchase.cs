namespace FruitWholesale.Domain.Entities;

public class Purchase
{
    public int PurchaseID { get; set; }
    public DateTime PurchaseDate { get; set; }
    public int SupplierID { get; set; }
    public string InvoiceNo { get; set; } = string.Empty;
    public string? Remarks { get; set; }
    public decimal TotalAmount { get; set; }
    public int? CreatedBy { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }

    public string? SupplierName { get; set; }
    public List<PurchaseItem> Items { get; set; } = [];
}

public class PurchaseItem
{
    public int PurchaseItemID { get; set; }
    public int PurchaseID { get; set; }
    public int FruitID { get; set; }
    public decimal Quantity { get; set; }
    public decimal PurchasePrice { get; set; }
    public decimal TotalAmount { get; set; }
    public int? BoxCount { get; set; }

    public string? FruitName { get; set; }
    public string? Unit { get; set; }
}
