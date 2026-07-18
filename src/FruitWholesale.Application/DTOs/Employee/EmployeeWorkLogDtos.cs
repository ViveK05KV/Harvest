namespace FruitWholesale.Application.DTOs.Employee;

public class EmployeeWorkLogDto
{
    public int EmployeeWorkLogID { get; set; }
    public DateTime WorkDate { get; set; }
    public int EmployeeID { get; set; }
    public string EmployeeName { get; set; } = string.Empty;
    public string JobType { get; set; } = string.Empty;
    public int? RouteID { get; set; }
    public string? RouteName { get; set; }
    public decimal Amount { get; set; }
    public string PaymentMode { get; set; } = string.Empty;
    public string? Remarks { get; set; }
}

public class SaveEmployeeWorkLogDto
{
    public int EmployeeWorkLogID { get; set; }
    public DateTime WorkDate { get; set; }
    public int EmployeeID { get; set; }
    public string JobType { get; set; } = string.Empty;
    public int? RouteID { get; set; }
    public decimal Amount { get; set; }
    public string PaymentMode { get; set; } = string.Empty;
    public string? Remarks { get; set; }
}
