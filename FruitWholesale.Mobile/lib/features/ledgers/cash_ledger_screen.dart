import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/widgets/paginated_list_view.dart';
import 'ledger_models.dart';
import 'ledger_service.dart';

class CashLedgerScreen extends StatelessWidget {
  const CashLedgerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = LedgerService(context.read<ApiClient>());
    final dateFormat = DateFormat('dd-MMM-yyyy');
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Scaffold(
      appBar: AppBar(title: const Text('Cash Ledger')),
      body: PaginatedListView<CashLedgerEntry>(
        fetchPage: (page) => service.getCashLedger(pageNumber: page),
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
    );
  }
}
