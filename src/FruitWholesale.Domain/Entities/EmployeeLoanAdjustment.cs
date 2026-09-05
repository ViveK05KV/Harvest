namespace FruitWholesale.Domain.Entities;

public class EmployeeLoanAdjustment
{
    public int EmployeeLoanAdjustmentID { get; set; }
    public int EmployeeID { get; set; }
    public DateTime AdjustmentDate { get; set; }
    public decimal Amount { get; set; }
    public bool IsIncrease { get; set; }
    public string Narration { get; set; } = string.Empty;
    public int? CreatedBy { get; set; }
    public DateTime CreatedAt { get; set; }
}
