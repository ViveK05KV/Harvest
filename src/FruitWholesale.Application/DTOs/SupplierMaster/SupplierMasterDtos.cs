namespace FruitWholesale.Application.DTOs.SupplierMaster;

public class SupplierMasterDto
{
    public int SupplierID { get; set; }
    public string SupplierName { get; set; } = string.Empty;
    public string? Phone { get; set; }
    public string? Address { get; set; }
    public decimal OpeningBalance { get; set; }
    public bool IsActive { get; set; }
    public decimal CurrentOutstanding { get; set; }

    /// <summary>
    /// Reverse of ShopMasterDto.LinkedSupplierID — the shop (if any) linked to
    /// this supplier as the same real-world party.
    /// </summary>
    public int? LinkedShopID { get; set; }
    public string? LinkedShopName { get; set; }

    /// <summary>
    /// The linked shop's outstanding minus this supplier's own outstanding —
    /// what the combined party owes you (positive) or you owe them (negative).
    /// Zero-valued (not meaningful) when not linked.
    /// </summary>
    public decimal NetBalance { get; set; }
}

public class CreateSupplierMasterDto
{
    public string SupplierName { get; set; } = string.Empty;
    public string? Phone { get; set; }
    public string? Address { get; set; }
    public decimal OpeningBalance { get; set; }
}

public class UpdateSupplierMasterDto
{
    public int SupplierID { get; set; }
    public string SupplierName { get; set; } = string.Empty;
    public string? Phone { get; set; }
    public string? Address { get; set; }
}
