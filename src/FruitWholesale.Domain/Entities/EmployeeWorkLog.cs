namespace FruitWholesale.Domain.Entities;

public class EmployeeWorkLog
{
    public int EmployeeWorkLogID { get; set; }
    public DateTime WorkDate { get; set; }
    public int EmployeeID { get; set; }
    public string JobType { get; set; } = string.Empty;
    public int? RouteID { get; set; }
    public decimal Amount { get; set; }
    public string PaymentMode { get; set; } = string.Empty;
    public string? Remarks { get; set; }
    public int? CreatedBy { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }

    public string? EmployeeName { get; set; }
    public string? RouteName { get; set; }
}
