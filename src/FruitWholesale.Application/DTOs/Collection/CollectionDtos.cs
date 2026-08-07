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
    public string CollectionType { get; set; } = string.Empty;
    public string TemporaryStatus { get; set; } = string.Empty;
    public int? SettlementID { get; set; }
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
    public string CollectionType { get; set; } = "Normal";
    public string TemporaryStatus { get; set; } = "None";
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
    public string CollectionType { get; set; } = "Normal";
    public string TemporaryStatus { get; set; } = "None";
}

public class SettleCollectionsRequestDto
{
    public int ShopID { get; set; }
    public DateTime SettlementDate { get; set; }
}

public class CollectionSettlementPreviewDto
{
    public int ShopID { get; set; }
    public string? ShopName { get; set; }
    public int PendingCount { get; set; }
    public decimal PendingTotal { get; set; }
}

public class CollectionSettlementResultDto
{
    public int SettlementID { get; set; }
    public int ShopID { get; set; }
    public DateTime SettlementDate { get; set; }
    public decimal TotalAmount { get; set; }
    public int PendingCount { get; set; }
}
