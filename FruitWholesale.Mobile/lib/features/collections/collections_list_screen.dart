import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/widgets/date_range_filter_row.dart';
import '../../core/widgets/paginated_list_view.dart';
import 'collection_form_screen.dart';
import 'collection_models.dart';
import 'collection_service.dart';
import 'settle_collections_dialog.dart';

class CollectionsListScreen extends StatefulWidget {
  const CollectionsListScreen({super.key});

  @override
  State<CollectionsListScreen> createState() => _CollectionsListScreenState();
}

class _CollectionsListScreenState extends State<CollectionsListScreen> {
  late final CollectionService _service = CollectionService(context.read<ApiClient>());
  static final _isoFormat = DateFormat('yyyy-MM-dd');
  Key _listKey = UniqueKey();
  DateTime? _fromDate;
  DateTime? _toDate;

  void _reload() => setState(() => _listKey = UniqueKey());

  void _onFromChanged(DateTime? date) => setState(() {
        _fromDate = date;
        _listKey = UniqueKey();
      });

  void _onToChanged(DateTime? date) => setState(() {
        _toDate = date;
        _listKey = UniqueKey();
      });

  Future<void> _openNewCollection() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CollectionFormScreen()),
    );
    if (created == true) _reload();
  }

  Future<void> _openSettleDeposits() async {
    final settled = await showSettleCollectionsDialog(context);
    if (settled == true) {
      _reload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Temporary collections settled.')));
      }
    }
  }

  void _openItem(Collection item) async {
    if (item.isSettled) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Settled temporary collections cannot be edited.')));
      return;
    }
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CollectionFormScreen(collectionId: item.collectionId)),
    );
    if (updated == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd-MMM-yyyy');
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Scaffold(
      body: Column(
        children: [
          DateRangeFilterRow(
            fromDate: _fromDate,
            toDate: _toDate,
            onFromChanged: _onFromChanged,
            onToChanged: _onToChanged,
          ),
          Expanded(
            child: PaginatedListView<Collection>(
              key: _listKey,
              fetchPage: (page) => _service.getPaged(
                pageNumber: page,
                fromDate: _fromDate != null ? _isoFormat.format(_fromDate!) : null,
                toDate: _toDate != null ? _isoFormat.format(_toDate!) : null,
              ),
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
                leading: CircleAvatar(
                  child: Icon(item.isTemporary ? Icons.account_balance_wallet_outlined : Icons.payments_outlined),
                ),
                title: Row(
                  children: [
                    Flexible(child: Text(item.shopName ?? '', overflow: TextOverflow.ellipsis)),
                    if (item.isTemporary) ...[
                      const SizedBox(width: 6),
                      Chip(
                        label: Text(item.temporaryStatus, style: const TextStyle(fontSize: 11)),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ],
                ),
                subtitle: Text(
                  '${dateFormat.format(item.collectionDate)} · ${item.paymentMode}'
                  '${item.discountAmount > 0 ? ' · Discount ${currencyFormat.format(item.discountAmount)}' : ''}',
                ),
                trailing: Text(
                  currencyFormat.format(item.amountReceived),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () => _openItem(item),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'settleDeposits',
            onPressed: _openSettleDeposits,
            tooltip: 'Settle Deposits',
            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
            child: const Icon(Icons.account_balance_wallet_outlined),
          ),
          const SizedBox(width: 12),
          FloatingActionButton.extended(
            heroTag: 'newCollection',
            onPressed: _openNewCollection,
            icon: const Icon(Icons.add),
            label: const Text('New Collection'),
          ),
        ],
      ),
    );
  }
}
