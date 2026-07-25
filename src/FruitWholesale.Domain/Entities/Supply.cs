namespace FruitWholesale.Domain.Entities;

public class Supply
{
    public int SupplyID { get; set; }
    public DateTime SupplyDate { get; set; }
    public int ShopID { get; set; }
    public string InvoiceNo { get; set; } = string.Empty;
    public string? Remarks { get; set; }
    public decimal TotalAmount { get; set; }
    public int? CreatedBy { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }

    public string? ShopName { get; set; }
    public List<SupplyItem> Items { get; set; } = [];
}

public class SupplyItem
{
    public int SupplyItemID { get; set; }
    public int SupplyID { get; set; }
    public int FruitID { get; set; }
    public decimal Quantity { get; set; }
    public decimal UnitPrice { get; set; }
    public decimal TotalAmount { get; set; }
    public decimal CostBasis { get; set; }

    public string? FruitName { get; set; }
    public string? Unit { get; set; }
}
