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

/// <summary>
/// Posts a manual correcting entry to a supplier's ledger (mirrors the
/// company Cash Adjustment). Editing OpeningBalance directly after creation
/// wouldn't move CurrentOutstanding, since that figure is always derived
/// from the ledger, not the OpeningBalance column.
/// </summary>
public class SupplierBalanceAdjustmentDto
{
    public decimal Amount { get; set; }

    /// <summary>True increases what the business owes this supplier (debit); false decreases it (credit).</summary>
    public bool IsIncrease { get; set; }
    public string Narration { get; set; } = string.Empty;
}
