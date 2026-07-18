namespace FruitWholesale.Application.DTOs.Employee;

public class EmployeeDto
{
    public int EmployeeID { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string? Phone { get; set; }
    public string? Address { get; set; }
    public bool IsActive { get; set; }
}

public class CreateEmployeeDto
{
    public string FullName { get; set; } = string.Empty;
    public string? Phone { get; set; }
    public string? Address { get; set; }
}

public class UpdateEmployeeDto
{
    public int EmployeeID { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string? Phone { get; set; }
    public string? Address { get; set; }
}
