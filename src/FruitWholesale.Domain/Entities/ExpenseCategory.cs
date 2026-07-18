namespace FruitWholesale.Domain.Entities;

public class ExpenseCategory
{
    public int ExpenseCategoryID { get; set; }
    public string CategoryName { get; set; } = string.Empty;
    public string? Description { get; set; }
    public bool IsActive { get; set; }
}
