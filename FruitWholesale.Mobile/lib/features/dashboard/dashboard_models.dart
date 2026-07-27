class DashboardSummary {
  final double currentCashBalance;
  final double todayCollection;
  final double todaySales;
  final double todayPurchases;
  final double todayExpenses;
  final double customerOutstanding;
  final double supplierOutstanding;
  final double netBusinessWorth;

  /// Admin-only; null for other roles (the API never populates these fields
  /// for a non-admin caller - see DashboardController).
  final double? totalProfit;
  final double? todayProfit;

  const DashboardSummary({
    required this.currentCashBalance,
    required this.todayCollection,
    required this.todaySales,
    required this.todayPurchases,
    required this.todayExpenses,
    required this.customerOutstanding,
    required this.supplierOutstanding,
    required this.netBusinessWorth,
    this.totalProfit,
    this.todayProfit,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    double d(String key) => (json[key] as num).toDouble();
    double? dOrNull(String key) => (json[key] as num?)?.toDouble();
    return DashboardSummary(
      currentCashBalance: d('currentCashBalance'),
      todayCollection: d('todayCollection'),
      todaySales: d('todaySales'),
      todayPurchases: d('todayPurchases'),
      todayExpenses: d('todayExpenses'),
      customerOutstanding: d('customerOutstanding'),
      supplierOutstanding: d('supplierOutstanding'),
      netBusinessWorth: d('netBusinessWorth'),
      totalProfit: dOrNull('totalProfit'),
      todayProfit: dOrNull('todayProfit'),
    );
  }
}

class TopFruit {
  final String fruitName;
  final double totalQuantity;
  final double totalAmount;

  const TopFruit({required this.fruitName, required this.totalQuantity, required this.totalAmount});

  factory TopFruit.fromJson(Map<String, dynamic> json) {
    return TopFruit(
      fruitName: json['fruitName'] as String,
      totalQuantity: (json['totalQuantity'] as num).toDouble(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
    );
  }
}

class TopCustomer {
  final String shopName;
  final double totalAmount;

  const TopCustomer({required this.shopName, required this.totalAmount});

  factory TopCustomer.fromJson(Map<String, dynamic> json) {
    return TopCustomer(
      shopName: json['shopName'] as String,
      totalAmount: (json['totalAmount'] as num).toDouble(),
    );
  }
}

class DashboardCharts {
  final List<TopFruit> topSellingFruits;
  final List<TopCustomer> topCustomers;

  const DashboardCharts({required this.topSellingFruits, required this.topCustomers});

  factory DashboardCharts.fromJson(Map<String, dynamic> json) {
    return DashboardCharts(
      topSellingFruits:
          (json['topSellingFruits'] as List).map((e) => TopFruit.fromJson(e as Map<String, dynamic>)).toList(),
      topCustomers: (json['topCustomers'] as List).map((e) => TopCustomer.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
