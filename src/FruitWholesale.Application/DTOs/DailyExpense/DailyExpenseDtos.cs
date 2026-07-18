namespace FruitWholesale.Application.DTOs.DailyExpense;

public class DailyExpenseDto
{
    public int ExpenseID { get; set; }
    public DateTime ExpenseDate { get; set; }
    public int ExpenseCategoryID { get; set; }
    public string? CategoryName { get; set; }
    public decimal Amount { get; set; }
    public string PaymentMode { get; set; } = string.Empty;
    public string? PaidTo { get; set; }
    public string? Description { get; set; }
}

public class CreateDailyExpenseDto
{
    public DateTime ExpenseDate { get; set; }
    public int ExpenseCategoryID { get; set; }
    public decimal Amount { get; set; }
    public string PaymentMode { get; set; } = string.Empty;
    public string? PaidTo { get; set; }
    public string? Description { get; set; }
}

public class UpdateDailyExpenseDto
{
    public int ExpenseID { get; set; }
    public DateTime ExpenseDate { get; set; }
    public int ExpenseCategoryID { get; set; }
    public decimal Amount { get; set; }
    public string PaymentMode { get; set; } = string.Empty;
    public string? PaidTo { get; set; }
    public string? Description { get; set; }
}
