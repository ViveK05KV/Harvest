namespace FruitWholesale.Domain.Entities;

public class RefreshToken
{
    public int RefreshTokenID { get; set; }
    public int UserID { get; set; }
    public string TokenHash { get; set; } = string.Empty;
    public DateTime ExpiresAt { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? RevokedAt { get; set; }
    public string? ReplacedByTokenHash { get; set; }
}
