import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/widgets/paginated_list_view.dart';
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
  Key _listKey = UniqueKey();

  void _reload() => setState(() => _listKey = UniqueKey());

  Future<void> _openNewPayment() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const SupplierPaymentFormScreen()),
    );
    if (created == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd-MMM-yyyy');
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Scaffold(
      appBar: AppBar(title: const Text('Supplier Payments')),
      body: PaginatedListView<SupplierPayment>(
        key: _listKey,
        fetchPage: (page) => _service.getPaged(pageNumber: page),
        padding: const EdgeInsets.only(bottom: 88),
        emptyState: const Column(
          children: [
            SizedBox(height: 80),
            Icon(Icons.account_balance_wallet_outlined, size: 48),
            SizedBox(height: 12),
            Center(child: Text('No supplier payments yet')),
          ],
        ),
        itemBuilder: (context, item) => ListTile(
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
            if (updated == true) _reload();
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNewPayment,
        icon: const Icon(Icons.add),
        label: const Text('New Payment'),
      ),
    );
  }
}
