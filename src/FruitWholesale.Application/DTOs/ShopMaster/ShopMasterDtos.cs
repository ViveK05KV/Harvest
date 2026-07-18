namespace FruitWholesale.Application.DTOs.ShopMaster;

public class ShopMasterDto
{
    public int ShopID { get; set; }
    public string ShopName { get; set; } = string.Empty;
    public string? OwnerName { get; set; }
    public string? Phone { get; set; }
    public string? Address { get; set; }
    public decimal OpeningBalance { get; set; }
    public decimal CreditLimit { get; set; }
    public int? RouteID { get; set; }
    public string? RouteName { get; set; }
    public bool IsActive { get; set; }
    public decimal CurrentOutstanding { get; set; }
}

public class CreateShopMasterDto
{
    public string ShopName { get; set; } = string.Empty;
    public string? OwnerName { get; set; }
    public string? Phone { get; set; }
    public string? Address { get; set; }
    public decimal OpeningBalance { get; set; }
    public decimal CreditLimit { get; set; }
    public int? RouteID { get; set; }
}

public class UpdateShopMasterDto
{
    public int ShopID { get; set; }
    public string ShopName { get; set; } = string.Empty;
    public string? OwnerName { get; set; }
    public string? Phone { get; set; }
    public string? Address { get; set; }
    public decimal CreditLimit { get; set; }
    public int? RouteID { get; set; }
}
