using FruitWholesale.Domain.Enums;

namespace FruitWholesale.Domain.Entities;

public class Collection
{
    public int CollectionID { get; set; }
    public DateTime CollectionDate { get; set; }
    public int ShopID { get; set; }
    public decimal AmountReceived { get; set; }
    public decimal DiscountAmount { get; set; }
    public string PaymentMode { get; set; } = string.Empty;
    public string? ReferenceNumber { get; set; }
    public string? Remarks { get; set; }
    public int? CreatedBy { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public string CollectionType { get; set; } = CollectionTypes.Normal;
    public string TemporaryStatus { get; set; } = TemporaryCollectionStatuses.None;
    public int? SettlementID { get; set; }

    public string? ShopName { get; set; }
    public DateTime? SettlementDate { get; set; }
    public decimal? SettledAmount { get; set; }
}
