namespace FruitWholesale.Domain.Entities;

public class FruitCostBasis
{
    public int FruitID { get; set; }
    public decimal QuantityOnHand { get; set; }
    public decimal AverageCost { get; set; }
    public DateTime UpdatedAt { get; set; }

    public string? FruitName { get; set; }
    public string? Unit { get; set; }
}
