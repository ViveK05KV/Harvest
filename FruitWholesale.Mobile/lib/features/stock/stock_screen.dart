import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import 'stock_adjustment_sheet.dart';
import 'stock_ledger_screen.dart';
import 'stock_models.dart';
import 'stock_service.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  late final StockService _service = StockService(context.read<ApiClient>());

  List<CurrentStock>? _items;
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
      final stock = await _service.getCurrentStock();
      setState(() => _items = stock);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _openAdjustment() async {
    final adjusted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const StockAdjustmentSheet(),
    );
    if (adjusted == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stock')),
      body: RefreshIndicator(onRefresh: _load, child: _buildBody()),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAdjustment,
        icon: const Icon(Icons.tune),
        label: const Text('Adjust'),
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
          Icon(Icons.inventory_outlined, size: 48),
          SizedBox(height: 12),
          Center(child: Text('No fruits configured yet')),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 88),
      itemCount: items.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = items[index];
        return ListTile(
          leading: const CircleAvatar(child: Icon(Icons.inventory_outlined)),
          title: Text(item.fruitName),
          trailing: Text('${item.currentStock} ${item.unit}', style: const TextStyle(fontWeight: FontWeight.w600)),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => StockLedgerScreen(fruitId: item.fruitId, fruitName: item.fruitName)),
          ),
        );
      },
    );
  }
}
