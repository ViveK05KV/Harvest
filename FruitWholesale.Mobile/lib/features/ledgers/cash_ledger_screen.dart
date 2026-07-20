import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import 'ledger_models.dart';
import 'ledger_service.dart';

class CashLedgerScreen extends StatefulWidget {
  const CashLedgerScreen({super.key});

  @override
  State<CashLedgerScreen> createState() => _CashLedgerScreenState();
}

class _CashLedgerScreenState extends State<CashLedgerScreen> {
  late final LedgerService _service = LedgerService(context.read<ApiClient>());

  List<CashLedgerEntry>? _entries;
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
      final page = await _service.getCashLedger();
      setState(() => _entries = page.items);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cash Ledger')),
      body: RefreshIndicator(onRefresh: _load, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading && _entries == null) {
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
    final entries = _entries ?? [];
    if (entries.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 80),
          Icon(Icons.account_balance_outlined, size: 48),
          SizedBox(height: 12),
          Center(child: Text('No cash transactions yet')),
        ],
      );
    }

    final dateFormat = DateFormat('dd-MMM-yyyy');
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return ListView.separated(
      itemCount: entries.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final entry = entries[index];
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
    );
  }
}
