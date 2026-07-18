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
