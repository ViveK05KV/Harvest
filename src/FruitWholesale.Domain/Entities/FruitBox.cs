namespace FruitWholesale.Domain.Entities;

/// <summary>
/// One physical box of a TracksByBox fruit. See database/18_AddFruitBoxTracking.sql
/// for the design rationale - this is a supplementary layer on top of StockLedger's
/// kg-only tracking, rebuilt from scratch on every Purchase/Supply write.
/// </summary>
public class FruitBox
{
    public int FruitBoxID { get; set; }
    public int FruitID { get; set; }
    public int? PurchaseID { get; set; }
    public decimal InitialWeightKg { get; set; }
    public decimal RemainingWeightKg { get; set; }
    public string Status { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
}
