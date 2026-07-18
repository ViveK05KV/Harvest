namespace FruitWholesale.Application.DTOs.Purchase;

public class PurchaseItemDto
{
    public int PurchaseItemID { get; set; }
    public int FruitID { get; set; }
    public string? FruitName { get; set; }
    public string? Unit { get; set; }
    public decimal Quantity { get; set; }
    public decimal PurchasePrice { get; set; }
    public decimal TotalAmount { get; set; }
}

public class PurchaseDto
{
    public int PurchaseID { get; set; }
    public DateTime PurchaseDate { get; set; }
    public int SupplierID { get; set; }
    public string? SupplierName { get; set; }
    public string InvoiceNo { get; set; } = string.Empty;
    public string? Remarks { get; set; }
    public decimal TotalAmount { get; set; }
    public List<PurchaseItemDto> Items { get; set; } = [];
}

public class PurchaseListItemDto
{
    public int PurchaseID { get; set; }
    public DateTime PurchaseDate { get; set; }
    public string SupplierName { get; set; } = string.Empty;
    public string InvoiceNo { get; set; } = string.Empty;
    public decimal TotalAmount { get; set; }
}

public class SavePurchaseItemDto
{
    public int FruitID { get; set; }
    public decimal Quantity { get; set; }
    public decimal PurchasePrice { get; set; }
}

public class CreatePurchaseDto
{
    public DateTime PurchaseDate { get; set; }
    public int SupplierID { get; set; }
    public string InvoiceNo { get; set; } = string.Empty;
    public string? Remarks { get; set; }
    public List<SavePurchaseItemDto> Items { get; set; } = [];
}

public class UpdatePurchaseDto
{
    public int PurchaseID { get; set; }
    public DateTime PurchaseDate { get; set; }
    public int SupplierID { get; set; }
    public string InvoiceNo { get; set; } = string.Empty;
    public string? Remarks { get; set; }
    public List<SavePurchaseItemDto> Items { get; set; } = [];
}
