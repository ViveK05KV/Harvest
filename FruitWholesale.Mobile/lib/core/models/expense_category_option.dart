/// Minimal expense-category shape used by dropdowns (from GET /expensecategory/active).
class ExpenseCategoryOption {
  final int expenseCategoryId;
  final String categoryName;

  const ExpenseCategoryOption({required this.expenseCategoryId, required this.categoryName});

  factory ExpenseCategoryOption.fromJson(Map<String, dynamic> json) {
    return ExpenseCategoryOption(
      expenseCategoryId: json['expenseCategoryID'] as int,
      categoryName: json['categoryName'] as String,
    );
  }
}
