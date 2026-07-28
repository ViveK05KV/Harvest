namespace FruitWholesale.Application.DTOs.ShopReturn;

public class ShopReturnItemDto
{
    public int ShopReturnItemID { get; set; }
    public int FruitID { get; set; }
    public string? FruitName { get; set; }
    public string? Unit { get; set; }
    public decimal Quantity { get; set; }
    public decimal UnitPrice { get; set; }
    public decimal TotalAmount { get; set; }
}

public class ShopReturnDto
{
    public int ShopReturnID { get; set; }
    public DateTime ReturnDate { get; set; }
    public int ShopID { get; set; }
    public string? ShopName { get; set; }
    public int? SupplyID { get; set; }
    public string? SupplyInvoiceNo { get; set; }
    public string ReferenceNo { get; set; } = string.Empty;
    public string? Remarks { get; set; }
    public decimal TotalAmount { get; set; }
    public List<ShopReturnItemDto> Items { get; set; } = [];
}

public class ShopReturnListItemDto
{
    public int ShopReturnID { get; set; }
    public DateTime ReturnDate { get; set; }
    public string ShopName { get; set; } = string.Empty;
    public string? SupplyInvoiceNo { get; set; }
    public string ReferenceNo { get; set; } = string.Empty;
    public decimal TotalAmount { get; set; }
}

public class SaveShopReturnItemDto
{
    public int FruitID { get; set; }
    public decimal Quantity { get; set; }
    public decimal UnitPrice { get; set; }
}

public class CreateShopReturnDto
{
    public DateTime ReturnDate { get; set; }
    public int ShopID { get; set; }
    public int? SupplyID { get; set; }
    public string ReferenceNo { get; set; } = string.Empty;
    public string? Remarks { get; set; }
    public List<SaveShopReturnItemDto> Items { get; set; } = [];
}

public class UpdateShopReturnDto
{
    public int ShopReturnID { get; set; }
    public DateTime ReturnDate { get; set; }
    public int ShopID { get; set; }
    public int? SupplyID { get; set; }
    public string ReferenceNo { get; set; } = string.Empty;
    public string? Remarks { get; set; }
    public List<SaveShopReturnItemDto> Items { get; set; } = [];
}
