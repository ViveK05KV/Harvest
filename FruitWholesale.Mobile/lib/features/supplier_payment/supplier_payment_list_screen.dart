import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import 'supplier_payment_form_screen.dart';
import 'supplier_payment_models.dart';
import 'supplier_payment_service.dart';

class SupplierPaymentListScreen extends StatefulWidget {
  const SupplierPaymentListScreen({super.key});

  @override
  State<SupplierPaymentListScreen> createState() => _SupplierPaymentListScreenState();
}

class _SupplierPaymentListScreenState extends State<SupplierPaymentListScreen> {
  late final SupplierPaymentService _service = SupplierPaymentService(context.read<ApiClient>());

  List<SupplierPayment>? _items;
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

  Future<void> _openNewPayment() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const SupplierPaymentFormScreen()),
    );
    if (created == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Supplier Payments')),
      body: RefreshIndicator(onRefresh: _load, child: _buildBody()),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNewPayment,
        icon: const Icon(Icons.add),
        label: const Text('New Payment'),
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
          Icon(Icons.account_balance_wallet_outlined, size: 48),
          SizedBox(height: 12),
          Center(child: Text('No supplier payments yet')),
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
          leading: const CircleAvatar(child: Icon(Icons.account_balance_wallet_outlined)),
          title: Text(item.supplierName ?? ''),
          subtitle: Text(
            '${dateFormat.format(item.paymentDate)} · ${item.paymentMode}'
            '${item.discountAmount > 0 ? ' · Discount ${currencyFormat.format(item.discountAmount)}' : ''}',
          ),
          trailing: Text(currencyFormat.format(item.amountPaid), style: const TextStyle(fontWeight: FontWeight.w600)),
          onTap: () async {
            final updated = await Navigator.of(context).push<bool>(
              MaterialPageRoute(builder: (_) => SupplierPaymentFormScreen(paymentId: item.supplierPaymentId)),
            );
            if (updated == true) _load();
          },
        );
      },
    );
  }
}
