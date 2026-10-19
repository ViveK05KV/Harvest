namespace FruitWholesale.Application.DTOs.Profit;

public class ActualProfitRow
{
    public DateTime Date { get; set; }
    public string? CustomerName { get; set; }
    public decimal Sales { get; set; }
    public decimal PurchaseCost { get; set; }
    public decimal ActualProfit { get; set; }
}

public class BusinessDailyProfitRow
{
    public DateTime Date { get; set; }
    public decimal Revenue { get; set; }
    public decimal Cost { get; set; }
    public decimal Profit { get; set; }
    public decimal Expenses { get; set; }
    public decimal NetProfit { get; set; }
    public decimal MarginPercent { get; set; }
}

public class ShopDailyProfitRow
{
    public DateTime Date { get; set; }
    public decimal Revenue { get; set; }
    public decimal Cost { get; set; }
    public decimal Profit { get; set; }
    public decimal MarginPercent { get; set; }
}

public class ShopProfitSummaryRow
{
    public int ShopID { get; set; }
    public string ShopName { get; set; } = string.Empty;
    public decimal Revenue { get; set; }
    public decimal Cost { get; set; }
    public decimal Profit { get; set; }
    public decimal MarginPercent { get; set; }
}

public class FruitProfitSummaryRow
{
    public int FruitID { get; set; }
    public string FruitName { get; set; } = string.Empty;
    public string Unit { get; set; } = string.Empty;
    public decimal QuantitySold { get; set; }
    public decimal Revenue { get; set; }
    public decimal Cost { get; set; }
    public decimal Profit { get; set; }
    public decimal MarginPercent { get; set; }
}

public class ShopFruitProfitRow
{
    public int ShopID { get; set; }
    public string ShopName { get; set; } = string.Empty;
    public int FruitID { get; set; }
    public string FruitName { get; set; } = string.Empty;
    public string Unit { get; set; } = string.Empty;
    public decimal QuantitySold { get; set; }
    public decimal Revenue { get; set; }
    public decimal Cost { get; set; }
    public decimal Profit { get; set; }
    public decimal MarginPercent { get; set; }
}

public class BusinessProfitTotal
{
    public decimal Revenue { get; set; }
    public decimal Cost { get; set; }
    public decimal Profit { get; set; }
    public decimal Expenses { get; set; }
    public decimal NetProfit { get; set; }
    public decimal MarginPercent { get; set; }
}
