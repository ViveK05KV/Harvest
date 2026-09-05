class ShopDailyProfitRow {
  final DateTime date;
  final double revenue;
  final double cost;
  final double profit;
  final double marginPercent;

  const ShopDailyProfitRow({
    required this.date,
    required this.revenue,
    required this.cost,
    required this.profit,
    required this.marginPercent,
  });

  factory ShopDailyProfitRow.fromJson(Map<String, dynamic> json) => ShopDailyProfitRow(
        date: DateTime.parse(json['date'] as String),
        revenue: (json['revenue'] as num).toDouble(),
        cost: (json['cost'] as num).toDouble(),
        profit: (json['profit'] as num).toDouble(),
        marginPercent: (json['marginPercent'] as num).toDouble(),
      );
}

class ShopProfitSummaryRow {
  final int shopId;
  final String shopName;
  final double revenue;
  final double cost;
  final double profit;
  final double marginPercent;

  const ShopProfitSummaryRow({
    required this.shopId,
    required this.shopName,
    required this.revenue,
    required this.cost,
    required this.profit,
    required this.marginPercent,
  });

  factory ShopProfitSummaryRow.fromJson(Map<String, dynamic> json) => ShopProfitSummaryRow(
        shopId: json['shopID'] as int,
        shopName: json['shopName'] as String,
        revenue: (json['revenue'] as num).toDouble(),
        cost: (json['cost'] as num).toDouble(),
        profit: (json['profit'] as num).toDouble(),
        marginPercent: (json['marginPercent'] as num).toDouble(),
      );
}

class FruitProfitSummaryRow {
  final int fruitId;
  final String fruitName;
  final String unit;
  final double quantitySold;
  final double revenue;
  final double cost;
  final double profit;
  final double marginPercent;

  const FruitProfitSummaryRow({
    required this.fruitId,
    required this.fruitName,
    required this.unit,
    required this.quantitySold,
    required this.revenue,
    required this.cost,
    required this.profit,
    required this.marginPercent,
  });

  factory FruitProfitSummaryRow.fromJson(Map<String, dynamic> json) => FruitProfitSummaryRow(
        fruitId: json['fruitID'] as int,
        fruitName: json['fruitName'] as String,
        unit: json['unit'] as String,
        quantitySold: (json['quantitySold'] as num).toDouble(),
        revenue: (json['revenue'] as num).toDouble(),
        cost: (json['cost'] as num).toDouble(),
        profit: (json['profit'] as num).toDouble(),
        marginPercent: (json['marginPercent'] as num).toDouble(),
      );
}

class ShopFruitProfitRow {
  final int shopId;
  final String shopName;
  final int fruitId;
  final String fruitName;
  final String unit;
  final double quantitySold;
  final double revenue;
  final double cost;
  final double profit;
  final double marginPercent;

  const ShopFruitProfitRow({
    required this.shopId,
    required this.shopName,
    required this.fruitId,
    required this.fruitName,
    required this.unit,
    required this.quantitySold,
    required this.revenue,
    required this.cost,
    required this.profit,
    required this.marginPercent,
  });

  factory ShopFruitProfitRow.fromJson(Map<String, dynamic> json) => ShopFruitProfitRow(
        shopId: json['shopID'] as int,
        shopName: json['shopName'] as String,
        fruitId: json['fruitID'] as int,
        fruitName: json['fruitName'] as String,
        unit: json['unit'] as String,
        quantitySold: (json['quantitySold'] as num).toDouble(),
        revenue: (json['revenue'] as num).toDouble(),
        cost: (json['cost'] as num).toDouble(),
        profit: (json['profit'] as num).toDouble(),
        marginPercent: (json['marginPercent'] as num).toDouble(),
      );
}

class BusinessProfitTotal {
  final double revenue;
  final double cost;
  final double profit;
  final double expenses;
  final double netProfit;
  final double marginPercent;

  const BusinessProfitTotal({
    required this.revenue,
    required this.cost,
    required this.profit,
    required this.expenses,
    required this.netProfit,
    required this.marginPercent,
  });

  factory BusinessProfitTotal.fromJson(Map<String, dynamic> json) => BusinessProfitTotal(
        revenue: (json['revenue'] as num).toDouble(),
        cost: (json['cost'] as num).toDouble(),
        profit: (json['profit'] as num).toDouble(),
        expenses: (json['expenses'] as num).toDouble(),
        netProfit: (json['netProfit'] as num).toDouble(),
        marginPercent: (json['marginPercent'] as num).toDouble(),
      );
}
