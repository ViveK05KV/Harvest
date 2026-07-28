import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/widgets/paginated_list_view.dart';
import 'supplier_return_form_screen.dart';
import 'supplier_return_models.dart';
import 'supplier_return_service.dart';

class SupplierReturnListScreen extends StatefulWidget {
  const SupplierReturnListScreen({super.key});

  @override
  State<SupplierReturnListScreen> createState() => _SupplierReturnListScreenState();
}

class _SupplierReturnListScreenState extends State<SupplierReturnListScreen> {
  late final SupplierReturnService _service = SupplierReturnService(context.read<ApiClient>());
  Key _listKey = UniqueKey();

  void _reload() => setState(() => _listKey = UniqueKey());

  Future<void> _openNew() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const SupplierReturnFormScreen()),
    );
    if (created == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd-MMM-yyyy');
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Scaffold(
      body: PaginatedListView<SupplierReturnListItem>(
        key: _listKey,
        fetchPage: (page) => _service.getPaged(pageNumber: page),
        padding: const EdgeInsets.only(bottom: 88),
        emptyState: const Column(
          children: [
            SizedBox(height: 80),
            Icon(Icons.keyboard_return_outlined, size: 48),
            SizedBox(height: 12),
            Center(child: Text('No supplier returns yet')),
          ],
        ),
        itemBuilder: (context, item) => ListTile(
          leading: const CircleAvatar(child: Icon(Icons.keyboard_return_outlined)),
          title: Text(item.supplierName),
          subtitle: Text('${item.referenceNo} · ${dateFormat.format(item.returnDate)}'),
          trailing: Text(
            currencyFormat.format(item.totalAmount),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          onTap: () async {
            final updated = await Navigator.of(context).push<bool>(
              MaterialPageRoute(builder: (_) => SupplierReturnFormScreen(supplierReturnId: item.supplierReturnId)),
            );
            if (updated == true) _reload();
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNew,
        icon: const Icon(Icons.add),
        label: const Text('New Return'),
      ),
    );
  }
}
