import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import 'stock_models.dart';
import 'stock_service.dart';

class StockLedgerScreen extends StatefulWidget {
  final int fruitId;
  final String fruitName;

  const StockLedgerScreen({super.key, required this.fruitId, required this.fruitName});

  @override
  State<StockLedgerScreen> createState() => _StockLedgerScreenState();
}

class _StockLedgerScreenState extends State<StockLedgerScreen> {
  late final StockService _service = StockService(context.read<ApiClient>());

  List<StockLedgerEntry>? _items;
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
      final page = await _service.getStockLedger(widget.fruitId);
      setState(() => _items = page.items);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.fruitName} Ledger')),
      body: RefreshIndicator(onRefresh: _load, child: _buildBody()),
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
          Icon(Icons.inventory_outlined, size: 48),
          SizedBox(height: 12),
          Center(child: Text('No stock movements yet')),
        ],
      );
    }

    final dateFormat = DateFormat('dd-MMM-yyyy');

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = items[index];
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
    );
  }
}
