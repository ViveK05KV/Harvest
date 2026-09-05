class DashboardSummary {
  final double currentCashBalance;
  final double todayCollection;
  final double todaySales;
  final double todayPurchases;
  final double todayExpenses;
  final double todaySalary;
  final double customerOutstanding;
  final double supplierOutstanding;
  final double netBusinessWorth;
  final double employeeLoanTotal;

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
    required this.todaySalary,
    required this.customerOutstanding,
    required this.supplierOutstanding,
    required this.netBusinessWorth,
    required this.employeeLoanTotal,
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
      todaySalary: d('todaySalary'),
      customerOutstanding: d('customerOutstanding'),
      supplierOutstanding: d('supplierOutstanding'),
      netBusinessWorth: d('netBusinessWorth'),
      employeeLoanTotal: d('employeeLoanTotal'),
      totalProfit: dOrNull('totalProfit'),
      todayProfit: dOrNull('todayProfit'),
    );
  }
}

class CategoryAmount {
  final String category;
  final double amount;

  const CategoryAmount({required this.category, required this.amount});

  factory CategoryAmount.fromJson(Map<String, dynamic> json) {
    return CategoryAmount(
      category: json['category'] as String,
      amount: (json['amount'] as num).toDouble(),
    );
  }
}

/// One of the four dashboard trend periods the backend accepts
/// (`Domain.Enums.DashboardPeriods`).
enum DashboardPeriod {
  thisWeek,
  thisMonth,
  last6Months,
  last12Months;

  String get toApi {
    switch (this) {
      case DashboardPeriod.thisWeek:
        return 'ThisWeek';
      case DashboardPeriod.thisMonth:
        return 'ThisMonth';
      case DashboardPeriod.last6Months:
        return 'Last6Months';
      case DashboardPeriod.last12Months:
        return 'Last12Months';
    }
  }

  String get label {
    switch (this) {
      case DashboardPeriod.thisWeek:
        return 'This Week';
      case DashboardPeriod.thisMonth:
        return 'This Month';
      case DashboardPeriod.last6Months:
        return 'Last 6 Months';
      case DashboardPeriod.last12Months:
        return 'Last 12 Months';
    }
  }
}

class TrendPoint {
  final String label;
  final double amount;

  const TrendPoint({required this.label, required this.amount});

  factory TrendPoint.fromJson(Map<String, dynamic> json) {
    return TrendPoint(
      label: json['label'] as String,
      amount: (json['amount'] as num).toDouble(),
    );
  }
}

class SalesVsPurchases {
  final List<TrendPoint> sales;
  final List<TrendPoint> purchases;

  const SalesVsPurchases({required this.sales, required this.purchases});

  factory SalesVsPurchases.fromJson(Map<String, dynamic> json) {
    return SalesVsPurchases(
      sales: (json['sales'] as List).map((e) => TrendPoint.fromJson(e as Map<String, dynamic>)).toList(),
      purchases: (json['purchases'] as List).map((e) => TrendPoint.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class DashboardCharts {
  final List<CategoryAmount> expensesByCategory;

  const DashboardCharts({required this.expensesByCategory});

  factory DashboardCharts.fromJson(Map<String, dynamic> json) {
    return DashboardCharts(
      expensesByCategory:
          (json['expensesByCategory'] as List).map((e) => CategoryAmount.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
