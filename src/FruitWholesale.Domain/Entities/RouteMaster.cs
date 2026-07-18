namespace FruitWholesale.Domain.Entities;

public class RouteMaster
{
    public int RouteID { get; set; }
    public string RouteName { get; set; } = string.Empty;
    public string? Description { get; set; }
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
}
