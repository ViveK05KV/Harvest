namespace FruitWholesale.Application.DTOs.ExpenseCategory;

public class ExpenseCategoryDto
{
    public int ExpenseCategoryID { get; set; }
    public string CategoryName { get; set; } = string.Empty;
    public string? Description { get; set; }
    public bool IsActive { get; set; }
}

public class CreateExpenseCategoryDto
{
    public string CategoryName { get; set; } = string.Empty;
    public string? Description { get; set; }
}

public class UpdateExpenseCategoryDto
{
    public int ExpenseCategoryID { get; set; }
    public string CategoryName { get; set; } = string.Empty;
    public string? Description { get; set; }
}
