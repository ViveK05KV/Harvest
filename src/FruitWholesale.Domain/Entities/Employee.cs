using FruitWholesale.Domain.Enums;

namespace FruitWholesale.Domain.Entities;

public class Employee
{
    public int EmployeeID { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string? Phone { get; set; }
    public string? Address { get; set; }
    public string SalaryType { get; set; } = SalaryTypes.Monthly;
    public decimal SalaryAmount { get; set; }
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
}
