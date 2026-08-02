import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/widgets/date_range_filter_row.dart';
import '../../core/widgets/paginated_list_view.dart';
import 'daily_expense_form_screen.dart';
import 'daily_expense_models.dart';
import 'daily_expense_service.dart';

class DailyExpenseListScreen extends StatefulWidget {
  const DailyExpenseListScreen({super.key});

  @override
  State<DailyExpenseListScreen> createState() => _DailyExpenseListScreenState();
}

class _DailyExpenseListScreenState extends State<DailyExpenseListScreen> {
  late final DailyExpenseService _service = DailyExpenseService(context.read<ApiClient>());
  static final _isoFormat = DateFormat('yyyy-MM-dd');
  Key _listKey = UniqueKey();
  DateTime? _fromDate;
  DateTime? _toDate;

  void _reload() => setState(() => _listKey = UniqueKey());

  void _onFromChanged(DateTime? date) => setState(() {
        _fromDate = date;
        _listKey = UniqueKey();
      });

  void _onToChanged(DateTime? date) => setState(() {
        _toDate = date;
        _listKey = UniqueKey();
      });

  Future<void> _openNewExpense() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const DailyExpenseFormScreen()),
    );
    if (created == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd-MMM-yyyy');
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Expenses')),
      body: Column(
        children: [
          DateRangeFilterRow(
            fromDate: _fromDate,
            toDate: _toDate,
            onFromChanged: _onFromChanged,
            onToChanged: _onToChanged,
          ),
          Expanded(
            child: PaginatedListView<DailyExpense>(
              key: _listKey,
              fetchPage: (page) => _service.getPaged(
                pageNumber: page,
                fromDate: _fromDate != null ? _isoFormat.format(_fromDate!) : null,
                toDate: _toDate != null ? _isoFormat.format(_toDate!) : null,
              ),
              padding: const EdgeInsets.only(bottom: 88),
              emptyState: const Column(
                children: [
                  SizedBox(height: 80),
                  Icon(Icons.receipt_long_outlined, size: 48),
                  SizedBox(height: 12),
                  Center(child: Text('No expenses yet')),
                ],
              ),
              itemBuilder: (context, item) => ListTile(
                leading: const CircleAvatar(child: Icon(Icons.receipt_long_outlined)),
                title: Text(item.categoryName ?? ''),
                subtitle: Text('${dateFormat.format(item.expenseDate)} · ${item.paymentMode}${item.paidTo != null ? ' · ${item.paidTo}' : ''}'),
                trailing: Text(currencyFormat.format(item.amount), style: const TextStyle(fontWeight: FontWeight.w600)),
                onTap: () async {
                  final updated = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(builder: (_) => DailyExpenseFormScreen(expenseId: item.expenseId)),
                  );
                  if (updated == true) _reload();
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNewExpense,
        icon: const Icon(Icons.add),
        label: const Text('New Expense'),
      ),
    );
  }
}
