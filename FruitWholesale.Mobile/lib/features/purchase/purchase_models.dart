/// Mirrors the backend's Purchase DTOs (PurchaseDtos.cs).
class PurchaseListItem {
  final int purchaseId;
  final DateTime purchaseDate;
  final String supplierName;
  final String invoiceNo;
  final double totalAmount;

  const PurchaseListItem({
    required this.purchaseId,
    required this.purchaseDate,
    required this.supplierName,
    required this.invoiceNo,
    required this.totalAmount,
  });

  factory PurchaseListItem.fromJson(Map<String, dynamic> json) {
    return PurchaseListItem(
      purchaseId: json['purchaseID'] as int,
      purchaseDate: DateTime.parse(json['purchaseDate'] as String),
      supplierName: json['supplierName'] as String,
      invoiceNo: json['invoiceNo'] as String,
      totalAmount: (json['totalAmount'] as num).toDouble(),
    );
  }
}

class PurchaseItem {
  final int purchaseItemId;
  final int fruitId;
  final String? fruitName;
  final String? unit;
  final double quantity;
  final double purchasePrice;
  final double totalAmount;

  const PurchaseItem({
    this.purchaseItemId = 0,
    required this.fruitId,
    this.fruitName,
    this.unit,
    required this.quantity,
    required this.purchasePrice,
    this.totalAmount = 0,
  });

  factory PurchaseItem.fromJson(Map<String, dynamic> json) {
    return PurchaseItem(
      purchaseItemId: json['purchaseItemID'] as int,
      fruitId: json['fruitID'] as int,
      fruitName: json['fruitName'] as String?,
      unit: json['unit'] as String?,
      quantity: (json['quantity'] as num).toDouble(),
      purchasePrice: (json['purchasePrice'] as num).toDouble(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toSaveJson() => {
        'fruitID': fruitId,
        'quantity': quantity,
        'purchasePrice': purchasePrice,
      };
}

class PurchaseDetail {
  final int purchaseId;
  final DateTime purchaseDate;
  final int supplierId;
  final String? supplierName;
  final String invoiceNo;
  final String? remarks;
  final double totalAmount;
  final List<PurchaseItem> items;

  const PurchaseDetail({
    this.purchaseId = 0,
    required this.purchaseDate,
    required this.supplierId,
    this.supplierName,
    required this.invoiceNo,
    this.remarks,
    this.totalAmount = 0,
    required this.items,
  });

  factory PurchaseDetail.fromJson(Map<String, dynamic> json) {
    return PurchaseDetail(
      purchaseId: json['purchaseID'] as int,
      purchaseDate: DateTime.parse(json['purchaseDate'] as String),
      supplierId: json['supplierID'] as int,
      supplierName: json['supplierName'] as String?,
      invoiceNo: json['invoiceNo'] as String,
      remarks: json['remarks'] as String?,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      items: (json['items'] as List).map((e) => PurchaseItem.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toSaveJson() => {
        'purchaseDate': purchaseDate.toIso8601String(),
        'supplierID': supplierId,
        'invoiceNo': invoiceNo,
        'remarks': remarks,
        'items': items.map((i) => i.toSaveJson()).toList(),
      };
}
