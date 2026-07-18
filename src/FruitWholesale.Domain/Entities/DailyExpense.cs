namespace FruitWholesale.Domain.Entities;

public class DailyExpense
{
    public int ExpenseID { get; set; }
    public DateTime ExpenseDate { get; set; }
    public int ExpenseCategoryID { get; set; }
    public decimal Amount { get; set; }
    public string PaymentMode { get; set; } = string.Empty;
    public string? PaidTo { get; set; }
    public string? Description { get; set; }
    public int? CreatedBy { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }

    public string? CategoryName { get; set; }
}
