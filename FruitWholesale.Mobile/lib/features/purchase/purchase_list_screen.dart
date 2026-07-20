import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/widgets/paginated_list_view.dart';
import 'purchase_form_screen.dart';
import 'purchase_models.dart';
import 'purchase_service.dart';

class PurchaseListScreen extends StatefulWidget {
  const PurchaseListScreen({super.key});

  @override
  State<PurchaseListScreen> createState() => _PurchaseListScreenState();
}

class _PurchaseListScreenState extends State<PurchaseListScreen> {
  late final PurchaseService _service = PurchaseService(context.read<ApiClient>());
  Key _listKey = UniqueKey();

  void _reload() => setState(() => _listKey = UniqueKey());

  Future<void> _openNewPurchase() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const PurchaseFormScreen()),
    );
    if (created == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd-MMM-yyyy');
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Scaffold(
      appBar: AppBar(title: const Text('Purchase')),
      body: PaginatedListView<PurchaseListItem>(
        key: _listKey,
        fetchPage: (page) => _service.getPaged(pageNumber: page),
        padding: const EdgeInsets.only(bottom: 88),
        emptyState: const Column(
          children: [
            SizedBox(height: 80),
            Icon(Icons.shopping_cart_outlined, size: 48),
            SizedBox(height: 12),
            Center(child: Text('No purchase invoices yet')),
          ],
        ),
        itemBuilder: (context, item) => ListTile(
          leading: const CircleAvatar(child: Icon(Icons.shopping_cart_outlined)),
          title: Text(item.supplierName),
          subtitle: Text('${item.invoiceNo} · ${dateFormat.format(item.purchaseDate)}'),
          trailing: Text(currencyFormat.format(item.totalAmount), style: const TextStyle(fontWeight: FontWeight.w600)),
          onTap: () async {
            final updated = await Navigator.of(context).push<bool>(
              MaterialPageRoute(builder: (_) => PurchaseFormScreen(purchaseId: item.purchaseId)),
            );
            if (updated == true) _reload();
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNewPurchase,
        icon: const Icon(Icons.add),
        label: const Text('New Purchase'),
      ),
    );
  }
}
