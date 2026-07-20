import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
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

  List<DailyExpense>? _items;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await _service.getPaged();
      setState(() => _items = page.items);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _openNewExpense() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const DailyExpenseFormScreen()),
    );
    if (created == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daily Expenses')),
      body: RefreshIndicator(onRefresh: _load, child: _buildBody()),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNewExpense,
        icon: const Icon(Icons.add),
        label: const Text('New Expense'),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _items == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 12),
          Center(child: Text(_error!, textAlign: TextAlign.center)),
        ],
      );
    }
    final items = _items ?? [];
    if (items.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 80),
          Icon(Icons.receipt_long_outlined, size: 48),
          SizedBox(height: 12),
          Center(child: Text('No expenses yet')),
        ],
      );
    }

    final dateFormat = DateFormat('dd-MMM-yyyy');
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 88),
      itemCount: items.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = items[index];
        return ListTile(
          leading: const CircleAvatar(child: Icon(Icons.receipt_long_outlined)),
          title: Text(item.categoryName ?? ''),
          subtitle: Text('${dateFormat.format(item.expenseDate)} · ${item.paymentMode}${item.paidTo != null ? ' · ${item.paidTo}' : ''}'),
          trailing: Text(currencyFormat.format(item.amount), style: const TextStyle(fontWeight: FontWeight.w600)),
          onTap: () async {
            final updated = await Navigator.of(context).push<bool>(
              MaterialPageRoute(builder: (_) => DailyExpenseFormScreen(expenseId: item.expenseId)),
            );
            if (updated == true) _load();
          },
        );
      },
    );
  }
}
