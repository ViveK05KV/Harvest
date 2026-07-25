namespace FruitWholesale.Application.DTOs.Dashboard;

public class DashboardSummaryDto
{
    public decimal CurrentCashBalance { get; set; }
    public decimal TodayCollection { get; set; }
    public decimal TodaySales { get; set; }
    public decimal TodayPurchases { get; set; }
    public decimal TodayExpenses { get; set; }
    public decimal CustomerOutstanding { get; set; }
    public decimal SupplierOutstanding { get; set; }
    public decimal NetBusinessWorth { get; set; }

    /// <summary>Admin-only; left null for other roles so profit figures never reach non-admin clients.</summary>
    public decimal? TotalProfit { get; set; }

    /// <summary>Admin-only; left null for other roles so profit figures never reach non-admin clients.</summary>
    public decimal? TodayProfit { get; set; }
}

public class MonthlyAmountDto
{
    public string Month { get; set; } = string.Empty;
    public decimal Amount { get; set; }
}

public class CategoryAmountDto
{
    public string Category { get; set; } = string.Empty;
    public decimal Amount { get; set; }
}

public class TopFruitDto
{
    public string FruitName { get; set; } = string.Empty;
    public decimal TotalQuantity { get; set; }
    public decimal TotalAmount { get; set; }
}

public class TopCustomerDto
{
    public string ShopName { get; set; } = string.Empty;
    public decimal TotalAmount { get; set; }
}

public class DashboardChartsDto
{
    public List<MonthlyAmountDto> SalesByMonth { get; set; } = [];
    public List<MonthlyAmountDto> CollectionsByMonth { get; set; } = [];
    public List<CategoryAmountDto> ExpensesByCategory { get; set; } = [];
    public List<TopFruitDto> TopSellingFruits { get; set; } = [];
    public List<TopCustomerDto> TopCustomers { get; set; } = [];
}
