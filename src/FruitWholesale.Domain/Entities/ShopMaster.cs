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

    public string? RouteName { get; set; }
}
