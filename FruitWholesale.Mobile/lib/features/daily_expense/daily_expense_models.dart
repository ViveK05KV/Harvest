export '../collections/collection_models.dart' show paymentModes;

/// Mirrors the backend's DailyExpense DTOs (DailyExpenseDtos.cs).
class DailyExpense {
  final int expenseId;
  final DateTime expenseDate;
  final int expenseCategoryId;
  final String? categoryName;
  final double amount;
  final String paymentMode;
  final String? paidTo;
  final String? description;

  const DailyExpense({
    this.expenseId = 0,
    required this.expenseDate,
    required this.expenseCategoryId,
    this.categoryName,
    required this.amount,
    this.paymentMode = 'Cash',
    this.paidTo,
    this.description,
  });

  factory DailyExpense.fromJson(Map<String, dynamic> json) {
    return DailyExpense(
      expenseId: json['expenseID'] as int,
      expenseDate: DateTime.parse(json['expenseDate'] as String),
      expenseCategoryId: json['expenseCategoryID'] as int,
      categoryName: json['categoryName'] as String?,
      amount: (json['amount'] as num).toDouble(),
      paymentMode: json['paymentMode'] as String,
      paidTo: json['paidTo'] as String?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toSaveJson() => {
        'expenseDate': expenseDate.toIso8601String(),
        'expenseCategoryID': expenseCategoryId,
        'amount': amount,
        'paymentMode': paymentMode,
        'paidTo': paidTo,
        'description': description,
      };
}
