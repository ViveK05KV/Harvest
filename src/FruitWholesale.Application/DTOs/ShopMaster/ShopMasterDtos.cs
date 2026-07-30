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

    /// <summary>
    /// Optional link to a SupplierMaster row for a party that is both a shop
    /// and a supplier. Null unless linked.
    /// </summary>
    public int? LinkedSupplierID { get; set; }
    public string? LinkedSupplierName { get; set; }

    /// <summary>
    /// CurrentOutstanding minus the linked supplier's outstanding balance —
    /// what this party owes you (positive) or you owe them (negative) net of
    /// both roles. Equal to CurrentOutstanding when not linked.
    /// </summary>
    public decimal NetBalance { get; set; }
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
    public int? LinkedSupplierID { get; set; }
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
    public int? LinkedSupplierID { get; set; }
}
