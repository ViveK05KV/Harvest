namespace FruitWholesale.Domain.Entities;

public class ShopReturn
{
    public int ShopReturnID { get; set; }
    public DateTime ReturnDate { get; set; }
    public int ShopID { get; set; }
    public int? SupplyID { get; set; }
    public string ReferenceNo { get; set; } = string.Empty;
    public string? Remarks { get; set; }
    public decimal TotalAmount { get; set; }
    public int? CreatedBy { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }

    public string? ShopName { get; set; }
    public string? SupplyInvoiceNo { get; set; }
    public List<ShopReturnItem> Items { get; set; } = [];
}

public class ShopReturnItem
{
    public int ShopReturnItemID { get; set; }
    public int ShopReturnID { get; set; }
    public int FruitID { get; set; }
    public decimal Quantity { get; set; }
    public decimal UnitPrice { get; set; }
    public decimal TotalAmount { get; set; }

    /// <summary>
    /// Cost this returned stock re-enters inventory at. Set once when the
    /// return is created (defaulted from the original SupplyItem's
    /// CostBasis when linked, otherwise the fruit's current average cost)
    /// and then read by RecalculateFruitCostBasisAsync exactly like
    /// PurchaseItems.PurchasePrice — an input to the weighted-average
    /// blend, not something the replay computes.
    /// </summary>
    public decimal CostBasis { get; set; }
    public int? BoxCount { get; set; }

    public string? FruitName { get; set; }
    public string? Unit { get; set; }
}
