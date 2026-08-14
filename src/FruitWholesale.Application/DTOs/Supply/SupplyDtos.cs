namespace FruitWholesale.Application.DTOs.Supply;

public class SupplyItemDto
{
    public int SupplyItemID { get; set; }
    public int FruitID { get; set; }
    public string? FruitName { get; set; }
    public string? Unit { get; set; }
    public decimal Quantity { get; set; }
    public decimal UnitPrice { get; set; }
    public decimal TotalAmount { get; set; }
    public decimal? BoxCount { get; set; }
}

public class SupplyDto
{
    public int SupplyID { get; set; }
    public DateTime SupplyDate { get; set; }
    public int ShopID { get; set; }
    public string? ShopName { get; set; }
    public string InvoiceNo { get; set; } = string.Empty;
    public string? Remarks { get; set; }
    public decimal TotalAmount { get; set; }
    public List<SupplyItemDto> Items { get; set; } = [];
}

public class SupplyListItemDto
{
    public int SupplyID { get; set; }
    public DateTime SupplyDate { get; set; }
    public string ShopName { get; set; } = string.Empty;
    public string InvoiceNo { get; set; } = string.Empty;
    public decimal TotalAmount { get; set; }
}

public class SaveSupplyItemDto
{
    public int FruitID { get; set; }
    public decimal Quantity { get; set; }
    public decimal UnitPrice { get; set; }
    public decimal? BoxCount { get; set; }
}

public class CreateSupplyDto
{
    public DateTime SupplyDate { get; set; }
    public int ShopID { get; set; }
    public string InvoiceNo { get; set; } = string.Empty;
    public string? Remarks { get; set; }
    public List<SaveSupplyItemDto> Items { get; set; } = [];
}

public class UpdateSupplyDto
{
    public int SupplyID { get; set; }
    public DateTime SupplyDate { get; set; }
    public int ShopID { get; set; }
    public string InvoiceNo { get; set; } = string.Empty;
    public string? Remarks { get; set; }
    public List<SaveSupplyItemDto> Items { get; set; } = [];
}
