class ExpenseCategory {
  final int expenseCategoryId;
  final String categoryName;
  final String? description;
  final bool isActive;

  const ExpenseCategory({
    this.expenseCategoryId = 0,
    required this.categoryName,
    this.description,
    this.isActive = true,
  });

  factory ExpenseCategory.fromJson(Map<String, dynamic> json) {
    return ExpenseCategory(
      expenseCategoryId: json['expenseCategoryID'] as int,
      categoryName: json['categoryName'] as String,
      description: json['description'] as String?,
      isActive: json['isActive'] as bool,
    );
  }

  Map<String, dynamic> toSaveJson() => {
        'categoryName': categoryName,
        'description': description,
      };
}
