/// Mirrors the backend's Supplier Return DTOs (SupplierReturnDtos.cs).
class SupplierReturnListItem {
  final int supplierReturnId;
  final DateTime returnDate;
  final String supplierName;
  final String? purchaseInvoiceNo;
  final String referenceNo;
  final double totalAmount;

  const SupplierReturnListItem({
    required this.supplierReturnId,
    required this.returnDate,
    required this.supplierName,
    this.purchaseInvoiceNo,
    required this.referenceNo,
    required this.totalAmount,
  });

  factory SupplierReturnListItem.fromJson(Map<String, dynamic> json) {
    return SupplierReturnListItem(
      supplierReturnId: json['supplierReturnID'] as int,
      returnDate: DateTime.parse(json['returnDate'] as String),
      supplierName: json['supplierName'] as String,
      purchaseInvoiceNo: json['purchaseInvoiceNo'] as String?,
      referenceNo: json['referenceNo'] as String,
      totalAmount: (json['totalAmount'] as num).toDouble(),
    );
  }
}

class SupplierReturnItem {
  final int supplierReturnItemId;
  final int fruitId;
  final String? fruitName;
  final String? unit;
  final double quantity;
  final double unitPrice;
  final double totalAmount;

  const SupplierReturnItem({
    this.supplierReturnItemId = 0,
    required this.fruitId,
    this.fruitName,
    this.unit,
    required this.quantity,
    required this.unitPrice,
    this.totalAmount = 0,
  });

  factory SupplierReturnItem.fromJson(Map<String, dynamic> json) {
    return SupplierReturnItem(
      supplierReturnItemId: json['supplierReturnItemID'] as int,
      fruitId: json['fruitID'] as int,
      fruitName: json['fruitName'] as String?,
      unit: json['unit'] as String?,
      quantity: (json['quantity'] as num).toDouble(),
      unitPrice: (json['unitPrice'] as num).toDouble(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toSaveJson() => {
        'fruitID': fruitId,
        'quantity': quantity,
        'unitPrice': unitPrice,
      };
}

class SupplierReturnDetail {
  final int supplierReturnId;
  final DateTime returnDate;
  final int supplierId;
  final String? supplierName;
  final int? purchaseId;
  final String? purchaseInvoiceNo;
  final String referenceNo;
  final String? remarks;
  final double totalAmount;
  final List<SupplierReturnItem> items;

  const SupplierReturnDetail({
    this.supplierReturnId = 0,
    required this.returnDate,
    required this.supplierId,
    this.supplierName,
    this.purchaseId,
    this.purchaseInvoiceNo,
    required this.referenceNo,
    this.remarks,
    this.totalAmount = 0,
    required this.items,
  });

  factory SupplierReturnDetail.fromJson(Map<String, dynamic> json) {
    return SupplierReturnDetail(
      supplierReturnId: json['supplierReturnID'] as int,
      returnDate: DateTime.parse(json['returnDate'] as String),
      supplierId: json['supplierID'] as int,
      supplierName: json['supplierName'] as String?,
      purchaseId: json['purchaseID'] as int?,
      purchaseInvoiceNo: json['purchaseInvoiceNo'] as String?,
      referenceNo: json['referenceNo'] as String,
      remarks: json['remarks'] as String?,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      items: (json['items'] as List).map((e) => SupplierReturnItem.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toSaveJson() => {
        'returnDate': returnDate.toIso8601String(),
        'supplierID': supplierId,
        'purchaseID': purchaseId,
        'referenceNo': referenceNo,
        'remarks': remarks,
        'items': items.map((i) => i.toSaveJson()).toList(),
      };
}
