namespace FruitWholesale.Domain.Entities;

public class SupplierPayment
{
    public int SupplierPaymentID { get; set; }
    public DateTime PaymentDate { get; set; }
    public int SupplierID { get; set; }
    public decimal AmountPaid { get; set; }
    public decimal DiscountAmount { get; set; }
    public string PaymentMode { get; set; } = string.Empty;
    public string? ReferenceNumber { get; set; }
    public string? Remarks { get; set; }
    public int? CreatedBy { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }

    public string? SupplierName { get; set; }
}
