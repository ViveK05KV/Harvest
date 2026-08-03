import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/widgets/net_balance_badge.dart';
import '../../core/widgets/paginated_list_view.dart';
import '../shop_master/shop_master_models.dart';
import '../shop_master/shop_master_service.dart';
import 'ledger_models.dart';
import 'ledger_service.dart';

class _FilterOption {
  final int? id;
  final String label;
  const _FilterOption(this.id, this.label);
}

class ShopLedgerScreen extends StatefulWidget {
  const ShopLedgerScreen({super.key});

  @override
  State<ShopLedgerScreen> createState() => _ShopLedgerScreenState();
}

class _ShopLedgerScreenState extends State<ShopLedgerScreen> {
  late final LedgerService _ledgerService = LedgerService(context.read<ApiClient>());
  late final ShopMasterService _shopService = ShopMasterService(context.read<ApiClient>());

  List<ShopMaster> _shops = [];
  int? _selectedShopId;
  String? _error;
  bool _loadingShops = true;

  @override
  void initState() {
    super.initState();
    _loadShops();
  }

  Future<void> _loadShops() async {
    try {
      final shops = await _shopService.getAllActive();
      setState(() {
        _shops = shops;
        _loadingShops = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _loadingShops = false;
      });
    }
  }

  ShopMaster? get _selectedShop {
    if (_selectedShopId == null) return null;
    for (final shop in _shops) {
      if (shop.shopId == _selectedShopId) return shop;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd-MMM-yyyy');
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Scaffold(
      appBar: AppBar(title: const Text('Shop Ledger')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _loadingShops
                ? const LinearProgressIndicator()
                : Autocomplete<_FilterOption>(
                    initialValue: TextEditingValue(text: _selectedShop?.shopName ?? ''),
                    displayStringForOption: (opt) => opt.label,
                    optionsBuilder: (value) {
                      final query = value.text.trim().toLowerCase();
                      final all = [
                        const _FilterOption(null, 'All Shops'),
                        ..._shops.map((s) => _FilterOption(s.shopId, s.shopName)),
                      ];
                      if (query.isEmpty) return all;
                      return all.where((o) => o.label.toLowerCase().contains(query));
                    },
                    onSelected: (opt) => setState(() => _selectedShopId = opt.id),
                    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) => TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: const InputDecoration(labelText: 'Select Shop'),
                    ),
                  ),
          ),
          if (_selectedShop != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: NetBalanceBadge(
                netBalance: _selectedShop!.netBalance,
                tooltip: _selectedShop!.linkedSupplierId != null
                    ? 'Combined position with linked Supplier: ${_selectedShop!.linkedSupplierName}'
                    : "${_selectedShop!.shopName}'s outstanding balance",
              ),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          if (_selectedShopId == null)
            const Expanded(child: Center(child: Text('Select a shop to view its ledger')))
          else
            Expanded(
              child: PaginatedListView<LedgerEntry>(
                key: ValueKey(_selectedShopId),
                fetchPage: (page) => _ledgerService.getShopLedger(_selectedShopId!, pageNumber: page),
                emptyState: const Column(
                  children: [SizedBox(height: 80), Center(child: Text('No transactions yet'))],
                ),
                itemBuilder: (context, entry) {
                  final isCredit = entry.credit > 0;
                  return ListTile(
                    title: Text(entry.transactionType),
                    subtitle: Text(
                      '${dateFormat.format(entry.transactionDate)}${entry.narration != null ? ' · ${entry.narration}' : ''}',
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          isCredit ? '-${currencyFormat.format(entry.credit)}' : '+${currencyFormat.format(entry.debit)}',
                          style: TextStyle(fontWeight: FontWeight.w600, color: isCredit ? Colors.green : Colors.red),
                        ),
                        Text('Bal: ${currencyFormat.format(entry.runningBalance)}', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
