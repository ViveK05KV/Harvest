import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/widgets/paginated_list_view.dart';
import 'stock_models.dart';
import 'stock_service.dart';

class StockLedgerScreen extends StatelessWidget {
  final int fruitId;
  final String fruitName;

  const StockLedgerScreen({super.key, required this.fruitId, required this.fruitName});

  @override
  Widget build(BuildContext context) {
    final service = StockService(context.read<ApiClient>());
    final dateFormat = DateFormat('dd-MMM-yyyy');

    return Scaffold(
      appBar: AppBar(title: Text('$fruitName Ledger')),
      body: PaginatedListView<StockLedgerEntry>(
        fetchPage: (page) => service.getStockLedger(fruitId, pageNumber: page),
        emptyState: const Column(
          children: [
            SizedBox(height: 80),
            Icon(Icons.inventory_outlined, size: 48),
            SizedBox(height: 12),
            Center(child: Text('No stock movements yet')),
          ],
        ),
        itemBuilder: (context, item) {
          final isIn = item.quantityIn > 0;
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: isIn
                  ? Theme.of(context).colorScheme.secondaryContainer
                  : Theme.of(context).colorScheme.errorContainer,
              child: Icon(isIn ? Icons.arrow_downward : Icons.arrow_upward, size: 18),
            ),
            title: Text(item.transactionType),
            subtitle: Text('${dateFormat.format(item.transactionDate)}${item.narration != null ? ' · ${item.narration}' : ''}'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isIn ? '+${item.quantityIn}' : '-${item.quantityOut}',
                  style: TextStyle(fontWeight: FontWeight.w600, color: isIn ? Colors.green : Colors.red),
                ),
                Text('Bal: ${item.runningStock}', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          );
        },
      ),
    );
  }
}
