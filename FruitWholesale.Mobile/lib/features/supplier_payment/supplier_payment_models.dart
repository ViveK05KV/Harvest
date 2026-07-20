export '../collections/collection_models.dart' show paymentModes;

/// Mirrors the backend's SupplierPayment DTOs (SupplierPaymentDtos.cs).
class SupplierPayment {
  final int supplierPaymentId;
  final DateTime paymentDate;
  final int supplierId;
  final String? supplierName;
  final double amountPaid;
  final double discountAmount;
  final String paymentMode;
  final String? referenceNumber;
  final String? remarks;

  const SupplierPayment({
    this.supplierPaymentId = 0,
    required this.paymentDate,
    required this.supplierId,
    this.supplierName,
    required this.amountPaid,
    this.discountAmount = 0,
    this.paymentMode = 'Cash',
    this.referenceNumber,
    this.remarks,
  });

  factory SupplierPayment.fromJson(Map<String, dynamic> json) {
    return SupplierPayment(
      supplierPaymentId: json['supplierPaymentID'] as int,
      paymentDate: DateTime.parse(json['paymentDate'] as String),
      supplierId: json['supplierID'] as int,
      supplierName: json['supplierName'] as String?,
      amountPaid: (json['amountPaid'] as num).toDouble(),
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0,
      paymentMode: json['paymentMode'] as String,
      referenceNumber: json['referenceNumber'] as String?,
      remarks: json['remarks'] as String?,
    );
  }

  Map<String, dynamic> toSaveJson() => {
        'paymentDate': paymentDate.toIso8601String(),
        'supplierID': supplierId,
        'amountPaid': amountPaid,
        'discountAmount': discountAmount,
        'paymentMode': paymentMode,
        'referenceNumber': referenceNumber,
        'remarks': remarks,
      };
}
