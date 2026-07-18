namespace FruitWholesale.Domain.Entities;

public class FruitMaster
{
    public int FruitID { get; set; }
    public string FruitName { get; set; } = string.Empty;
    public string Unit { get; set; } = string.Empty;
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
}
