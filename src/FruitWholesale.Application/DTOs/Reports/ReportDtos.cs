namespace FruitWholesale.Application.DTOs.Reports;

public class DailySalesReportRow
{
    public DateTime SupplyDate { get; set; }
    public string InvoiceNo { get; set; } = string.Empty;
    public string ShopName { get; set; } = string.Empty;
    public decimal TotalAmount { get; set; }
}

public class DailyCollectionReportRow
{
    public DateTime CollectionDate { get; set; }
    public string ShopName { get; set; } = string.Empty;
    public decimal AmountReceived { get; set; }
    public string PaymentMode { get; set; } = string.Empty;
}

public class DailyExpenseReportRow
{
    public DateTime ExpenseDate { get; set; }
    public string CategoryName { get; set; } = string.Empty;
    public decimal Amount { get; set; }
    public string PaidTo { get; set; } = string.Empty;
    public string PaymentMode { get; set; } = string.Empty;
}

public class PurchaseReportRow
{
    public DateTime PurchaseDate { get; set; }
    public string InvoiceNo { get; set; } = string.Empty;
    public string SupplierName { get; set; } = string.Empty;
    public decimal TotalAmount { get; set; }
}

public class FruitSalesReportRow
{
    public string FruitName { get; set; } = string.Empty;
    public string Unit { get; set; } = string.Empty;
    public decimal TotalQuantity { get; set; }
    public decimal TotalAmount { get; set; }
}

public class OutstandingReportRow
{
    public string Name { get; set; } = string.Empty;
    public string Type { get; set; } = string.Empty; // "Customer" or "Supplier"
    public decimal OutstandingAmount { get; set; }
}

public class ProfitSummaryReportRow
{
    public string Month { get; set; } = string.Empty;
    public decimal TotalSales { get; set; }
    public decimal TotalPurchases { get; set; }
    public decimal TotalExpenses { get; set; }
    public decimal NetProfit { get; set; }
}
