namespace FruitWholesale.Application.DTOs.CompanySettings;

public class CompanySettingsDto
{
    public int CompanyID { get; set; }
    public string CompanyName { get; set; } = string.Empty;
    public string? OwnerName { get; set; }
    public string? Address { get; set; }
    public string? Phone { get; set; }
    public string? GSTNo { get; set; }
    public string? LogoUrl { get; set; }
    public decimal OpeningCashBalance { get; set; }
    public bool ReportsVisibleToManagers { get; set; }
    public bool ProfitVisibleToManagers { get; set; }
}

public class SetReportsVisibilityDto
{
    public bool Visible { get; set; }
}

public class SetProfitVisibilityDto
{
    public bool Visible { get; set; }
}

public class UpsertCompanySettingsDto
{
    public string CompanyName { get; set; } = string.Empty;
    public string? OwnerName { get; set; }
    public string? Address { get; set; }
    public string? Phone { get; set; }
    public string? GSTNo { get; set; }
    public decimal OpeningCashBalance { get; set; }
}

public class CashAdjustmentDto
{
    public decimal Amount { get; set; }
    public bool IsIncrease { get; set; }
    public string Narration { get; set; } = string.Empty;
}
