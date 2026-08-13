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
  final String collectionType;
  final String temporaryStatus;
  final int? settlementId;

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
    this.collectionType = 'Normal',
    this.temporaryStatus = 'None',
    this.settlementId,
  });

  bool get isTemporary => collectionType == 'Temporary';
  bool get isSettled => temporaryStatus == 'Settled';

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
      collectionType: json['collectionType'] as String? ?? 'Normal',
      temporaryStatus: json['temporaryStatus'] as String? ?? 'None',
      settlementId: json['settlementID'] as int?,
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
        'collectionType': collectionType,
        'temporaryStatus': temporaryStatus,
      };
}

/// Mirrors CollectionSettlementPreviewDto.
class CollectionSettlementPreview {
  final int shopId;
  final String? shopName;
  final int pendingCount;
  final double pendingTotal;

  const CollectionSettlementPreview({
    required this.shopId,
    this.shopName,
    required this.pendingCount,
    required this.pendingTotal,
  });

  factory CollectionSettlementPreview.fromJson(Map<String, dynamic> json) {
    return CollectionSettlementPreview(
      shopId: json['shopID'] as int,
      shopName: json['shopName'] as String?,
      pendingCount: json['pendingCount'] as int,
      pendingTotal: (json['pendingTotal'] as num).toDouble(),
    );
  }
}

/// Mirrors CollectionSettlementResultDto.
class CollectionSettlementResult {
  final int settlementId;
  final int shopId;
  final DateTime settlementDate;
  final double totalAmount;
  final int pendingCount;

  const CollectionSettlementResult({
    required this.settlementId,
    required this.shopId,
    required this.settlementDate,
    required this.totalAmount,
    required this.pendingCount,
  });

  factory CollectionSettlementResult.fromJson(Map<String, dynamic> json) {
    return CollectionSettlementResult(
      settlementId: json['settlementID'] as int,
      shopId: json['shopID'] as int,
      settlementDate: DateTime.parse(json['settlementDate'] as String),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      pendingCount: json['pendingCount'] as int,
    );
  }
}
