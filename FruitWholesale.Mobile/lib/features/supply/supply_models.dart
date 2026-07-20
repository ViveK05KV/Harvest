/// Mirrors the backend's Supply DTOs (SupplyDtos.cs).
class SupplyListItem {
  final int supplyId;
  final DateTime supplyDate;
  final String shopName;
  final String invoiceNo;
  final double totalAmount;

  const SupplyListItem({
    required this.supplyId,
    required this.supplyDate,
    required this.shopName,
    required this.invoiceNo,
    required this.totalAmount,
  });

  factory SupplyListItem.fromJson(Map<String, dynamic> json) {
    return SupplyListItem(
      supplyId: json['supplyID'] as int,
      supplyDate: DateTime.parse(json['supplyDate'] as String),
      shopName: json['shopName'] as String,
      invoiceNo: json['invoiceNo'] as String,
      totalAmount: (json['totalAmount'] as num).toDouble(),
    );
  }
}

class SupplyItem {
  final int supplyItemId;
  final int fruitId;
  final String? fruitName;
  final String? unit;
  final double quantity;
  final double unitPrice;
  final double totalAmount;

  const SupplyItem({
    this.supplyItemId = 0,
    required this.fruitId,
    this.fruitName,
    this.unit,
    required this.quantity,
    required this.unitPrice,
    this.totalAmount = 0,
  });

  factory SupplyItem.fromJson(Map<String, dynamic> json) {
    return SupplyItem(
      supplyItemId: json['supplyItemID'] as int,
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

class SupplyDetail {
  final int supplyId;
  final DateTime supplyDate;
  final int shopId;
  final String? shopName;
  final String invoiceNo;
  final String? remarks;
  final double totalAmount;
  final List<SupplyItem> items;

  const SupplyDetail({
    this.supplyId = 0,
    required this.supplyDate,
    required this.shopId,
    this.shopName,
    required this.invoiceNo,
    this.remarks,
    this.totalAmount = 0,
    required this.items,
  });

  factory SupplyDetail.fromJson(Map<String, dynamic> json) {
    return SupplyDetail(
      supplyId: json['supplyID'] as int,
      supplyDate: DateTime.parse(json['supplyDate'] as String),
      shopId: json['shopID'] as int,
      shopName: json['shopName'] as String?,
      invoiceNo: json['invoiceNo'] as String,
      remarks: json['remarks'] as String?,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      items: (json['items'] as List).map((e) => SupplyItem.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toSaveJson() => {
        'supplyDate': supplyDate.toIso8601String(),
        'shopID': shopId,
        'invoiceNo': invoiceNo,
        'remarks': remarks,
        'items': items.map((i) => i.toSaveJson()).toList(),
      };
}
