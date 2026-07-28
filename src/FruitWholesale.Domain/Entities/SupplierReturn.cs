namespace FruitWholesale.Domain.Entities;

public class SupplierReturn
{
    public int SupplierReturnID { get; set; }
    public DateTime ReturnDate { get; set; }
    public int SupplierID { get; set; }
    public int? PurchaseID { get; set; }
    public string ReferenceNo { get; set; } = string.Empty;
    public string? Remarks { get; set; }
    public decimal TotalAmount { get; set; }
    public int? CreatedBy { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }

    public string? SupplierName { get; set; }
    public string? PurchaseInvoiceNo { get; set; }
    public List<SupplierReturnItem> Items { get; set; } = [];
}

public class SupplierReturnItem
{
    public int SupplierReturnItemID { get; set; }
    public int SupplierReturnID { get; set; }
    public int FruitID { get; set; }
    public decimal Quantity { get; set; }
    public decimal UnitPrice { get; set; }
    public decimal TotalAmount { get; set; }

    /// <summary>
    /// Weighted-average cost of this fruit at the moment stock left for
    /// the supplier. Snapshotted by RecalculateFruitCostBasisAsync exactly
    /// like SupplyItems.CostBasis — an output the replay writes, not an
    /// input the caller supplies.
    /// </summary>
    public decimal CostBasis { get; set; }

    public string? FruitName { get; set; }
    public string? Unit { get; set; }
}
