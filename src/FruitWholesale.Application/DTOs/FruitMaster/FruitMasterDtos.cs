namespace FruitWholesale.Application.DTOs.FruitMaster;

public class FruitMasterDto
{
    public int FruitID { get; set; }
    public string FruitName { get; set; } = string.Empty;
    public string Unit { get; set; } = string.Empty;
    public bool IsActive { get; set; }
}

public class CreateFruitMasterDto
{
    public string FruitName { get; set; } = string.Empty;
    public string Unit { get; set; } = string.Empty;
}

public class UpdateFruitMasterDto
{
    public int FruitID { get; set; }
    public string FruitName { get; set; } = string.Empty;
    public string Unit { get; set; } = string.Empty;
}
