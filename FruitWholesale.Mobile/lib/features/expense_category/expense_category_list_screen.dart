import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/widgets/master_list_screen.dart';
import 'expense_category_form_screen.dart';
import 'expense_category_models.dart';
import 'expense_category_service.dart';

class ExpenseCategoryListScreen extends StatelessWidget {
  const ExpenseCategoryListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = ExpenseCategoryService(context.read<ApiClient>());
    return MasterListScreen<ExpenseCategory>(
      title: 'Expense Categories',
      emptyLabel: 'No expense categories yet',
      emptyIcon: Icons.category_outlined,
      fetchPaged: service.getPaged,
      idOf: (c) => c.expenseCategoryId,
      titleOf: (c) => c.categoryName,
      subtitleOf: (c) => c.description ?? '',
      isActiveOf: (c) => c.isActive,
      onSetActive: service.setActive,
      formBuilder: (context, {id}) => ExpenseCategoryFormScreen(expenseCategoryId: id),
    );
  }
}
