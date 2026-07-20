import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/widgets/paginated_list_view.dart';
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
  Key _listKey = UniqueKey();

  void _reload() => setState(() => _listKey = UniqueKey());

  Future<void> _openNewSupply() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const SupplyFormScreen()),
    );
    if (created == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd-MMM-yyyy');
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Scaffold(
      body: PaginatedListView<SupplyListItem>(
        key: _listKey,
        fetchPage: (page) => _service.getPaged(pageNumber: page),
        padding: const EdgeInsets.only(bottom: 88),
        emptyState: const Column(
          children: [
            SizedBox(height: 80),
            Icon(Icons.local_shipping_outlined, size: 48),
            SizedBox(height: 12),
            Center(child: Text('No supply invoices yet')),
          ],
        ),
        itemBuilder: (context, item) => ListTile(
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
            if (updated == true) _reload();
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNewSupply,
        icon: const Icon(Icons.add),
        label: const Text('New Supply'),
      ),
    );
  }
}
