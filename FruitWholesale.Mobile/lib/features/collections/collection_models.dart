/// Matches PAYMENT_MODES in the backend/Angular models.
const List<String> paymentModes = ['Cash', 'Bank', 'UPI', 'Cheque'];

/// Mirrors the backend's Collection DTOs (CollectionDtos.cs).
class Collection {
  final int collectionId;
  final DateTime collectionDate;
  final int shopId;
  final String? shopName;
  final double amountReceived;
  final double discountAmount;
  final String paymentMode;
  final String? referenceNumber;
  final String? remarks;

  const Collection({
    this.collectionId = 0,
    required this.collectionDate,
    required this.shopId,
    this.shopName,
    required this.amountReceived,
    this.discountAmount = 0,
    required this.paymentMode,
    this.referenceNumber,
    this.remarks,
  });

  factory Collection.fromJson(Map<String, dynamic> json) {
    return Collection(
      collectionId: json['collectionID'] as int,
      collectionDate: DateTime.parse(json['collectionDate'] as String),
      shopId: json['shopID'] as int,
      shopName: json['shopName'] as String?,
      amountReceived: (json['amountReceived'] as num).toDouble(),
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0,
      paymentMode: json['paymentMode'] as String,
      referenceNumber: json['referenceNumber'] as String?,
      remarks: json['remarks'] as String?,
    );
  }

  Map<String, dynamic> toSaveJson() => {
        'collectionDate': collectionDate.toIso8601String(),
        'shopID': shopId,
        'amountReceived': amountReceived,
        'discountAmount': discountAmount,
        'paymentMode': paymentMode,
        'referenceNumber': referenceNumber,
        'remarks': remarks,
      };
}
