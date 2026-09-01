namespace FruitWholesale.Application.DTOs.Dashboard;

public class DashboardSummaryDto
{
    public decimal CurrentCashBalance { get; set; }
    public decimal TodayCollection { get; set; }
    public decimal TodaySales { get; set; }
    public decimal TodayPurchases { get; set; }
    public decimal TodayExpenses { get; set; }
    public decimal TodaySalary { get; set; }
    public decimal CustomerOutstanding { get; set; }
    public decimal SupplierOutstanding { get; set; }
    public decimal NetBusinessWorth { get; set; }

    /// <summary>Gross profit (revenue minus cost of goods sold) since profit tracking
    /// began. Admin-only; left null for other roles so profit figures never reach
    /// non-admin clients.</summary>
    public decimal? TotalProfit { get; set; }

    /// <summary>Today's gross profit (today's revenue minus cost of goods sold).
    /// Admin-only; left null for other roles so profit figures never reach
    /// non-admin clients.</summary>
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

/// <summary>One point on a trend chart. "Label" is already formatted for display
/// (e.g. "Mon", "14", "Jul") so the client doesn't need to know the period's
/// granularity to render an axis tick.</summary>
public class TrendPointDto
{
    public string Label { get; set; } = string.Empty;
    public decimal Amount { get; set; }
}

public class SalesVsPurchasesDto
{
    public List<TrendPointDto> Sales { get; set; } = [];
    public List<TrendPointDto> Purchases { get; set; } = [];
}
