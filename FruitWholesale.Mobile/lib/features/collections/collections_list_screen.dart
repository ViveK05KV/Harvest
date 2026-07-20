import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/widgets/paginated_list_view.dart';
import 'collection_form_screen.dart';
import 'collection_models.dart';
import 'collection_service.dart';

class CollectionsListScreen extends StatefulWidget {
  const CollectionsListScreen({super.key});

  @override
  State<CollectionsListScreen> createState() => _CollectionsListScreenState();
}

class _CollectionsListScreenState extends State<CollectionsListScreen> {
  late final CollectionService _service = CollectionService(context.read<ApiClient>());
  Key _listKey = UniqueKey();

  void _reload() => setState(() => _listKey = UniqueKey());

  Future<void> _openNewCollection() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CollectionFormScreen()),
    );
    if (created == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd-MMM-yyyy');
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Scaffold(
      body: PaginatedListView<Collection>(
        key: _listKey,
        fetchPage: (page) => _service.getPaged(pageNumber: page),
        padding: const EdgeInsets.only(bottom: 88),
        emptyState: const Column(
          children: [
            SizedBox(height: 80),
            Icon(Icons.payments_outlined, size: 48),
            SizedBox(height: 12),
            Center(child: Text('No collections yet')),
          ],
        ),
        itemBuilder: (context, item) => ListTile(
          leading: const CircleAvatar(child: Icon(Icons.payments_outlined)),
          title: Text(item.shopName ?? ''),
          subtitle: Text(
            '${dateFormat.format(item.collectionDate)} · ${item.paymentMode}'
            '${item.discountAmount > 0 ? ' · Discount ${currencyFormat.format(item.discountAmount)}' : ''}',
          ),
          trailing: Text(
            currencyFormat.format(item.amountReceived),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          onTap: () async {
            final updated = await Navigator.of(context).push<bool>(
              MaterialPageRoute(builder: (_) => CollectionFormScreen(collectionId: item.collectionId)),
            );
            if (updated == true) _reload();
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNewCollection,
        icon: const Icon(Icons.add),
        label: const Text('New Collection'),
      ),
    );
  }
}
