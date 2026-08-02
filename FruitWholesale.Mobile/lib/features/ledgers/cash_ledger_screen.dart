import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/widgets/paginated_list_view.dart';
import 'ledger_models.dart';
import 'ledger_service.dart';

class CashLedgerScreen extends StatefulWidget {
  const CashLedgerScreen({super.key});

  @override
  State<CashLedgerScreen> createState() => _CashLedgerScreenState();
}

class _CashLedgerScreenState extends State<CashLedgerScreen> {
  late final LedgerService _service = LedgerService(context.read<ApiClient>());
  Key _listKey = UniqueKey();
  String? _transactionType;
  double? _currentBalance;

  @override
  void initState() {
    super.initState();
    _service.getCurrentCashBalance().then((balance) => setState(() => _currentBalance = balance));
  }

  void _onTypeChanged(String? value) {
    setState(() {
      _transactionType = value;
      _listKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd-MMM-yyyy');
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Scaffold(
      appBar: AppBar(title: const Text('Cash Ledger')),
      body: Column(
        children: [
          if (_currentBalance != null) _CurrentBalanceBox(balance: _currentBalance!, currencyFormat: currencyFormat),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: DropdownButtonFormField<String?>(
                initialValue: _transactionType,
                decoration: const InputDecoration(labelText: 'Type', isDense: true),
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('All types')),
                  for (final entry in cashLedgerTypeLabels.entries)
                    DropdownMenuItem<String?>(value: entry.key, child: Text(entry.value)),
                ],
                onChanged: _onTypeChanged,
              ),
            ),
          ),
          Expanded(
            child: PaginatedListView<CashLedgerEntry>(
              key: _listKey,
              fetchPage: (page) => _service.getCashLedger(pageNumber: page, transactionType: _transactionType),
              emptyState: const Column(
                children: [
                  SizedBox(height: 80),
                  Icon(Icons.account_balance_outlined, size: 48),
                  SizedBox(height: 12),
                  Center(child: Text('No cash transactions yet')),
                ],
              ),
              itemBuilder: (context, entry) {
                final isIn = entry.cashIn > 0;
                return ListTile(
                  title: Text(entry.transactionType),
                  subtitle: Text(
                    '${dateFormat.format(entry.transactionDate)} · ${entry.paymentMode}${entry.narration != null ? ' · ${entry.narration}' : ''}',
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        isIn ? '+${currencyFormat.format(entry.cashIn)}' : '-${currencyFormat.format(entry.cashOut)}',
                        style: TextStyle(fontWeight: FontWeight.w600, color: isIn ? Colors.green : Colors.red),
                      ),
                      Text('Bal: ${currencyFormat.format(entry.runningBalance)}', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrentBalanceBox extends StatelessWidget {
  final double balance;
  final NumberFormat currencyFormat;

  const _CurrentBalanceBox({required this.balance, required this.currencyFormat});

  @override
  Widget build(BuildContext context) {
    final isNegative = balance < 0;
    final color = isNegative ? Colors.red.shade700 : Colors.green.shade700;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Current Balance', style: TextStyle(color: color, fontSize: 13)),
          Text(
            currencyFormat.format(balance),
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
