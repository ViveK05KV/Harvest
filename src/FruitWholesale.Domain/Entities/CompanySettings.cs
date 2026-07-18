namespace FruitWholesale.Domain.Entities;

public class CompanySettings
{
    public int CompanyID { get; set; }
    public string CompanyName { get; set; } = string.Empty;
    public string? OwnerName { get; set; }
    public string? Address { get; set; }
    public string? Phone { get; set; }
    public string? GSTNo { get; set; }
    public string? LogoUrl { get; set; }
    public decimal OpeningCashBalance { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
}
