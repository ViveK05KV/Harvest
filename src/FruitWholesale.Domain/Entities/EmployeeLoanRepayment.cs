namespace FruitWholesale.Domain.Entities;

public class EmployeeLoanRepayment
{
    public int EmployeeLoanRepaymentID { get; set; }
    public int EmployeeID { get; set; }
    public DateTime RepaymentDate { get; set; }
    public decimal Amount { get; set; }
    public string PaymentMode { get; set; } = string.Empty;
    public string? Remarks { get; set; }
    public int? CreatedBy { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }

    public string? EmployeeName { get; set; }
}
