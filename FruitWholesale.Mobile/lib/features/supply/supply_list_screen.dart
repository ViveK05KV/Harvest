import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import 'supply_form_screen.dart';
import 'supply_models.dart';
import 'supply_service.dart';

class SupplyListScreen extends StatefulWidget {
  const SupplyListScreen({super.key});

  @override
  State<SupplyListScreen> createState() => _SupplyListScreenState();
}

class _SupplyListScreenState extends State<SupplyListScreen> {
  late final SupplyService _service = SupplyService(context.read<ApiClient>());

  List<SupplyListItem>? _items;
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

  Future<void> _openNewSupply() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const SupplyFormScreen()),
    );
    if (created == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNewSupply,
        icon: const Icon(Icons.add),
        label: const Text('New Supply'),
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
          Icon(Icons.local_shipping_outlined, size: 48),
          SizedBox(height: 12),
          Center(child: Text('No supply invoices yet')),
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
          leading: const CircleAvatar(child: Icon(Icons.local_shipping_outlined)),
          title: Text(item.shopName),
          subtitle: Text('${item.invoiceNo} · ${dateFormat.format(item.supplyDate)}'),
          trailing: Text(
            currencyFormat.format(item.totalAmount),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          onTap: () async {
            final updated = await Navigator.of(context).push<bool>(
              MaterialPageRoute(builder: (_) => SupplyFormScreen(supplyId: item.supplyId)),
            );
            if (updated == true) _load();
          },
        );
      },
    );
  }
}
