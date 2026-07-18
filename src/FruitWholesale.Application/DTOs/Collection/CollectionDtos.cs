namespace FruitWholesale.Application.DTOs.Collection;

public class CollectionDto
{
    public int CollectionID { get; set; }
    public DateTime CollectionDate { get; set; }
    public int ShopID { get; set; }
    public string? ShopName { get; set; }
    public decimal AmountReceived { get; set; }
    public decimal DiscountAmount { get; set; }
    public string PaymentMode { get; set; } = string.Empty;
    public string? ReferenceNumber { get; set; }
    public string? Remarks { get; set; }
}

public class CreateCollectionDto
{
    public DateTime CollectionDate { get; set; }
    public int ShopID { get; set; }
    public decimal AmountReceived { get; set; }
    public decimal DiscountAmount { get; set; }
    public string PaymentMode { get; set; } = string.Empty;
    public string? ReferenceNumber { get; set; }
    public string? Remarks { get; set; }
}

public class UpdateCollectionDto
{
    public int CollectionID { get; set; }
    public DateTime CollectionDate { get; set; }
    public int ShopID { get; set; }
    public decimal AmountReceived { get; set; }
    public decimal DiscountAmount { get; set; }
    public string PaymentMode { get; set; } = string.Empty;
    public string? ReferenceNumber { get; set; }
    public string? Remarks { get; set; }
}
