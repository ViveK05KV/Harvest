import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/widgets/date_range_filter_row.dart';
import '../../core/widgets/paginated_list_view.dart';
import '../shop_master/shop_master_models.dart';
import '../shop_master/shop_master_service.dart';
import 'collection_form_screen.dart';
import 'collection_models.dart';
import 'collection_service.dart';
import 'settle_collections_dialog.dart';

class _ShopFilterOption {
  final int? id;
  final String label;
  const _ShopFilterOption(this.id, this.label);
}

class CollectionsListScreen extends StatefulWidget {
  const CollectionsListScreen({super.key});

  @override
  State<CollectionsListScreen> createState() => _CollectionsListScreenState();
}

class _CollectionsListScreenState extends State<CollectionsListScreen> {
  late final CollectionService _service = CollectionService(context.read<ApiClient>());
  late final ShopMasterService _shopService = ShopMasterService(context.read<ApiClient>());
  static final _isoFormat = DateFormat('yyyy-MM-dd');
  Key _listKey = UniqueKey();
  DateTime? _fromDate;
  DateTime? _toDate;

  final _shopController = TextEditingController();
  final _shopFocusNode = FocusNode();

  List<ShopMaster> _shops = [];
  int? _shopId;
  bool _loadingShops = true;

  @override
  void initState() {
    super.initState();
    _loadShops();
  }

  @override
  void dispose() {
    _shopController.dispose();
    _shopFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadShops() async {
    try {
      final shops = await _shopService.getAllActive();
      if (mounted) {
        setState(() {
          _shops = shops;
          _shopController.text = _selectedShop?.shopName ?? '';
        });
      }
    } on ApiException {
      // Shop filter just stays empty; the list itself still loads unfiltered.
    } finally {
      if (mounted) setState(() => _loadingShops = false);
    }
  }

  ShopMaster? get _selectedShop {
    for (final shop in _shops) {
      if (shop.shopId == _shopId) return shop;
    }
    return null;
  }

  void _onShopChanged(int? shopId) => setState(() {
        _shopId = shopId;
        _listKey = UniqueKey();
      });

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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _loadingShops
                ? const LinearProgressIndicator()
                : Autocomplete<_ShopFilterOption>(
                    textEditingController: _shopController,
                    focusNode: _shopFocusNode,
                    displayStringForOption: (opt) => opt.label,
                    optionsBuilder: (value) {
                      final query = value.text.trim().toLowerCase();
                      final all = [
                        const _ShopFilterOption(null, 'All Shops'),
                        ..._shops.map((s) => _ShopFilterOption(s.shopId, s.shopName)),
                      ];
                      if (query.isEmpty) return all;
                      return all.where((o) => o.label.toLowerCase().contains(query));
                    },
                    onSelected: (opt) {
                      _shopController.text = opt.label;
                      _onShopChanged(opt.id);
                    },
                    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: const InputDecoration(labelText: 'Filter by Shop', prefixIcon: Icon(Icons.storefront_outlined)),
                      );
                    },
                  ),
          ),
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
                shopId: _shopId,
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
