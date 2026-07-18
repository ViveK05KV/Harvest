namespace FruitWholesale.Application.DTOs.SupplierPayment;

public class SupplierPaymentDto
{
    public int SupplierPaymentID { get; set; }
    public DateTime PaymentDate { get; set; }
    public int SupplierID { get; set; }
    public string? SupplierName { get; set; }
    public decimal AmountPaid { get; set; }
    public decimal DiscountAmount { get; set; }
    public string PaymentMode { get; set; } = string.Empty;
    public string? ReferenceNumber { get; set; }
    public string? Remarks { get; set; }
}

public class CreateSupplierPaymentDto
{
    public DateTime PaymentDate { get; set; }
    public int SupplierID { get; set; }
    public decimal AmountPaid { get; set; }
    public decimal DiscountAmount { get; set; }
    public string PaymentMode { get; set; } = string.Empty;
    public string? ReferenceNumber { get; set; }
    public string? Remarks { get; set; }
}

public class UpdateSupplierPaymentDto
{
    public int SupplierPaymentID { get; set; }
    public DateTime PaymentDate { get; set; }
    public int SupplierID { get; set; }
    public decimal AmountPaid { get; set; }
    public decimal DiscountAmount { get; set; }
    public string PaymentMode { get; set; } = string.Empty;
    public string? ReferenceNumber { get; set; }
    public string? Remarks { get; set; }
}
