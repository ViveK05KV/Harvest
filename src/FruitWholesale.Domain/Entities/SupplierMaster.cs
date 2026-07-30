namespace FruitWholesale.Domain.Entities;

public class SupplierMaster
{
    public int SupplierID { get; set; }
    public string SupplierName { get; set; } = string.Empty;
    public string? Phone { get; set; }
    public string? Address { get; set; }
    public decimal OpeningBalance { get; set; }
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }

    /// <summary>
    /// Reverse of ShopMaster.LinkedSupplierID — the shop (if any) that links to
    /// this supplier as the same real-world party. Not a stored column; joined
    /// on read.
    /// </summary>
    public int? LinkedShopID { get; set; }
    public string? LinkedShopName { get; set; }
}
