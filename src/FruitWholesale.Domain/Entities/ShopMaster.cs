namespace FruitWholesale.Domain.Entities;

public class ShopMaster
{
    public int ShopID { get; set; }
    public string ShopName { get; set; } = string.Empty;
    public string? OwnerName { get; set; }
    public string? Phone { get; set; }
    public string? Address { get; set; }
    public decimal OpeningBalance { get; set; }
    public decimal CreditLimit { get; set; }
    public int? RouteID { get; set; }
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }

    /// <summary>
    /// Optional link to a SupplierMaster row representing the same real-world
    /// party (a shop that is also one of our suppliers). Lets us show a net
    /// receivable/payable position without merging the two independent ledgers.
    /// </summary>
    public int? LinkedSupplierID { get; set; }

    public string? RouteName { get; set; }
    public string? LinkedSupplierName { get; set; }
}
