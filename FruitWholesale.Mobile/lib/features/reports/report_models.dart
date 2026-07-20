class DailySalesRow {
  final DateTime supplyDate;
  final String invoiceNo;
  final String shopName;
  final double totalAmount;

  const DailySalesRow({required this.supplyDate, required this.invoiceNo, required this.shopName, required this.totalAmount});

  factory DailySalesRow.fromJson(Map<String, dynamic> json) => DailySalesRow(
        supplyDate: DateTime.parse(json['supplyDate'] as String),
        invoiceNo: json['invoiceNo'] as String,
        shopName: json['shopName'] as String,
        totalAmount: (json['totalAmount'] as num).toDouble(),
      );
}

class DailyCollectionRow {
  final DateTime collectionDate;
  final String shopName;
  final double amountReceived;
  final String paymentMode;

  const DailyCollectionRow({required this.collectionDate, required this.shopName, required this.amountReceived, required this.paymentMode});

  factory DailyCollectionRow.fromJson(Map<String, dynamic> json) => DailyCollectionRow(
        collectionDate: DateTime.parse(json['collectionDate'] as String),
        shopName: json['shopName'] as String,
        amountReceived: (json['amountReceived'] as num).toDouble(),
        paymentMode: json['paymentMode'] as String,
      );
}

class DailyExpenseRow {
  final DateTime expenseDate;
  final String categoryName;
  final double amount;
  final String paidTo;
  final String paymentMode;

  const DailyExpenseRow({
    required this.expenseDate,
    required this.categoryName,
    required this.amount,
    required this.paidTo,
    required this.paymentMode,
  });

  factory DailyExpenseRow.fromJson(Map<String, dynamic> json) => DailyExpenseRow(
        expenseDate: DateTime.parse(json['expenseDate'] as String),
        categoryName: json['categoryName'] as String,
        amount: (json['amount'] as num).toDouble(),
        paidTo: json['paidTo'] as String,
        paymentMode: json['paymentMode'] as String,
      );
}

class PurchaseReportRow {
  final DateTime purchaseDate;
  final String invoiceNo;
  final String supplierName;
  final double totalAmount;

  const PurchaseReportRow({required this.purchaseDate, required this.invoiceNo, required this.supplierName, required this.totalAmount});

  factory PurchaseReportRow.fromJson(Map<String, dynamic> json) => PurchaseReportRow(
        purchaseDate: DateTime.parse(json['purchaseDate'] as String),
        invoiceNo: json['invoiceNo'] as String,
        supplierName: json['supplierName'] as String,
        totalAmount: (json['totalAmount'] as num).toDouble(),
      );
}

class FruitSalesRow {
  final String fruitName;
  final String unit;
  final double totalQuantity;
  final double totalAmount;

  const FruitSalesRow({required this.fruitName, required this.unit, required this.totalQuantity, required this.totalAmount});

  factory FruitSalesRow.fromJson(Map<String, dynamic> json) => FruitSalesRow(
        fruitName: json['fruitName'] as String,
        unit: json['unit'] as String,
        totalQuantity: (json['totalQuantity'] as num).toDouble(),
        totalAmount: (json['totalAmount'] as num).toDouble(),
      );
}

class OutstandingRow {
  final String name;
  final String type;
  final double outstandingAmount;

  const OutstandingRow({required this.name, required this.type, required this.outstandingAmount});

  factory OutstandingRow.fromJson(Map<String, dynamic> json) => OutstandingRow(
        name: json['name'] as String,
        type: json['type'] as String,
        outstandingAmount: (json['outstandingAmount'] as num).toDouble(),
      );
}

class ProfitSummaryRow {
  final String month;
  final double totalSales;
  final double totalPurchases;
  final double totalExpenses;
  final double netProfit;

  const ProfitSummaryRow({
    required this.month,
    required this.totalSales,
    required this.totalPurchases,
    required this.totalExpenses,
    required this.netProfit,
  });

  factory ProfitSummaryRow.fromJson(Map<String, dynamic> json) => ProfitSummaryRow(
        month: json['month'] as String,
        totalSales: (json['totalSales'] as num).toDouble(),
        totalPurchases: (json['totalPurchases'] as num).toDouble(),
        totalExpenses: (json['totalExpenses'] as num).toDouble(),
        netProfit: (json['netProfit'] as num).toDouble(),
      );
}
