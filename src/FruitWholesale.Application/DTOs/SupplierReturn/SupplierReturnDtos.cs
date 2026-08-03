namespace FruitWholesale.Application.DTOs.SupplierReturn;

public class SupplierReturnItemDto
{
    public int SupplierReturnItemID { get; set; }
    public int FruitID { get; set; }
    public string? FruitName { get; set; }
    public string? Unit { get; set; }
    public decimal Quantity { get; set; }
    public decimal UnitPrice { get; set; }
    public decimal TotalAmount { get; set; }
    public decimal? BoxCount { get; set; }
}

public class SupplierReturnDto
{
    public int SupplierReturnID { get; set; }
    public DateTime ReturnDate { get; set; }
    public int SupplierID { get; set; }
    public string? SupplierName { get; set; }
    public int? PurchaseID { get; set; }
    public string? PurchaseInvoiceNo { get; set; }
    public string ReferenceNo { get; set; } = string.Empty;
    public string? Remarks { get; set; }
    public decimal TotalAmount { get; set; }
    public List<SupplierReturnItemDto> Items { get; set; } = [];
}

public class SupplierReturnListItemDto
{
    public int SupplierReturnID { get; set; }
    public DateTime ReturnDate { get; set; }
    public string SupplierName { get; set; } = string.Empty;
    public string? PurchaseInvoiceNo { get; set; }
    public string ReferenceNo { get; set; } = string.Empty;
    public decimal TotalAmount { get; set; }
}

public class SaveSupplierReturnItemDto
{
    public int FruitID { get; set; }
    public decimal Quantity { get; set; }
    public decimal UnitPrice { get; set; }
    public decimal? BoxCount { get; set; }
}

public class CreateSupplierReturnDto
{
    public DateTime ReturnDate { get; set; }
    public int SupplierID { get; set; }
    public int? PurchaseID { get; set; }
    public string ReferenceNo { get; set; } = string.Empty;
    public string? Remarks { get; set; }
    public List<SaveSupplierReturnItemDto> Items { get; set; } = [];
}

public class UpdateSupplierReturnDto
{
    public int SupplierReturnID { get; set; }
    public DateTime ReturnDate { get; set; }
    public int SupplierID { get; set; }
    public int? PurchaseID { get; set; }
    public string ReferenceNo { get; set; } = string.Empty;
    public string? Remarks { get; set; }
    public List<SaveSupplierReturnItemDto> Items { get; set; } = [];
}
