namespace FruitWholesale.Application.DTOs.RouteMaster;

public class RouteMasterDto
{
    public int RouteID { get; set; }
    public string RouteName { get; set; } = string.Empty;
    public string? Description { get; set; }
    public bool IsActive { get; set; }
    public int ShopCount { get; set; }
}

public class CreateRouteMasterDto
{
    public string RouteName { get; set; } = string.Empty;
    public string? Description { get; set; }
}

public class UpdateRouteMasterDto
{
    public int RouteID { get; set; }
    public string RouteName { get; set; } = string.Empty;
    public string? Description { get; set; }
}
