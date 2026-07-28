/// Mirrors the backend's Shop Return DTOs (ShopReturnDtos.cs).
class ShopReturnListItem {
  final int shopReturnId;
  final DateTime returnDate;
  final String shopName;
  final String? supplyInvoiceNo;
  final String referenceNo;
  final double totalAmount;

  const ShopReturnListItem({
    required this.shopReturnId,
    required this.returnDate,
    required this.shopName,
    this.supplyInvoiceNo,
    required this.referenceNo,
    required this.totalAmount,
  });

  factory ShopReturnListItem.fromJson(Map<String, dynamic> json) {
    return ShopReturnListItem(
      shopReturnId: json['shopReturnID'] as int,
      returnDate: DateTime.parse(json['returnDate'] as String),
      shopName: json['shopName'] as String,
      supplyInvoiceNo: json['supplyInvoiceNo'] as String?,
      referenceNo: json['referenceNo'] as String,
      totalAmount: (json['totalAmount'] as num).toDouble(),
    );
  }
}

class ShopReturnItem {
  final int shopReturnItemId;
  final int fruitId;
  final String? fruitName;
  final String? unit;
  final double quantity;
  final double unitPrice;
  final double totalAmount;

  const ShopReturnItem({
    this.shopReturnItemId = 0,
    required this.fruitId,
    this.fruitName,
    this.unit,
    required this.quantity,
    required this.unitPrice,
    this.totalAmount = 0,
  });

  factory ShopReturnItem.fromJson(Map<String, dynamic> json) {
    return ShopReturnItem(
      shopReturnItemId: json['shopReturnItemID'] as int,
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

class ShopReturnDetail {
  final int shopReturnId;
  final DateTime returnDate;
  final int shopId;
  final String? shopName;
  final int? supplyId;
  final String? supplyInvoiceNo;
  final String referenceNo;
  final String? remarks;
  final double totalAmount;
  final List<ShopReturnItem> items;

  const ShopReturnDetail({
    this.shopReturnId = 0,
    required this.returnDate,
    required this.shopId,
    this.shopName,
    this.supplyId,
    this.supplyInvoiceNo,
    required this.referenceNo,
    this.remarks,
    this.totalAmount = 0,
    required this.items,
  });

  factory ShopReturnDetail.fromJson(Map<String, dynamic> json) {
    return ShopReturnDetail(
      shopReturnId: json['shopReturnID'] as int,
      returnDate: DateTime.parse(json['returnDate'] as String),
      shopId: json['shopID'] as int,
      shopName: json['shopName'] as String?,
      supplyId: json['supplyID'] as int?,
      supplyInvoiceNo: json['supplyInvoiceNo'] as String?,
      referenceNo: json['referenceNo'] as String,
      remarks: json['remarks'] as String?,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      items: (json['items'] as List).map((e) => ShopReturnItem.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toSaveJson() => {
        'returnDate': returnDate.toIso8601String(),
        'shopID': shopId,
        'supplyID': supplyId,
        'referenceNo': referenceNo,
        'remarks': remarks,
        'items': items.map((i) => i.toSaveJson()).toList(),
      };
}
