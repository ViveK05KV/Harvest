import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/lookup_service.dart';
import '../../core/models/shop_option.dart';
import 'collection_models.dart';
import 'collection_service.dart';

/// Settles all pending temporary deposits for a shop into one shop-ledger
/// credit, mirroring the web client's "Settle Temporary Deposits" dialog.
/// Cash was already received daily, so settlement doesn't book more cash.
Future<bool?> showSettleCollectionsDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (_) => const _SettleCollectionsDialog(),
  );
}

class _SettleCollectionsDialog extends StatefulWidget {
  const _SettleCollectionsDialog();

  @override
  State<_SettleCollectionsDialog> createState() => _SettleCollectionsDialogState();
}

class _SettleCollectionsDialogState extends State<_SettleCollectionsDialog> {
  late final CollectionService _collectionService = CollectionService(context.read<ApiClient>());
  late final LookupService _lookupService = LookupService(context.read<ApiClient>());
  final _shopController = TextEditingController();
  final _shopFocusNode = FocusNode();

  List<ShopOption> _shops = [];
  int? _selectedShopId;
  DateTime _settlementDate = DateTime.now();
  CollectionSettlementPreview? _previewData;
  bool _loadingShops = true;
  bool _previewing = false;
  bool _settling = false;
  bool _suppressShopListener = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _shopController.addListener(_onShopTextChanged);
    _loadShops();
  }

  @override
  void dispose() {
    _shopController.removeListener(_onShopTextChanged);
    _shopController.dispose();
    _shopFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadShops() async {
    final shops = await _lookupService.getActiveShops();
    if (!mounted) return;
    setState(() {
      _shops = shops;
      _loadingShops = false;
    });
  }

  // Typing away from the selected shop must invalidate the stale shopID -
  // otherwise Confirm stays enabled against a preview that no longer matches
  // the visible shop, and settle() would settle deposits for the wrong shop.
  // Skip the programmatic text write onSelected makes to itself below.
  void _onShopTextChanged() {
    if (_suppressShopListener) return;
    if (_selectedShopId != null) {
      setState(() {
        _selectedShopId = null;
        _previewData = null;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _settlementDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _settlementDate = picked);
  }

  Future<void> _loadPreview() async {
    final shopId = _selectedShopId;
    if (shopId == null) return;
    setState(() {
      _previewing = true;
      _error = null;
    });
    try {
      final preview = await _collectionService.getPendingSettlementPreview(shopId);
      if (!mounted) return;
      setState(() => _previewData = preview);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _previewing = false);
    }
  }

  Future<void> _confirm() async {
    final shopId = _selectedShopId;
    if (shopId == null || _previewData == null) return;
    setState(() {
      _settling = true;
      _error = null;
    });
    try {
      await _collectionService.settle(shopId: shopId, settlementDate: _settlementDate);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _settling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd-MMM-yyyy');
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
    final preview = _previewData;

    return AlertDialog(
      title: const Text('Settle Temporary Deposits'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
            ],
            if (_loadingShops)
              const Center(child: CircularProgressIndicator())
            else
              Autocomplete<ShopOption>(
                textEditingController: _shopController,
                focusNode: _shopFocusNode,
                displayStringForOption: (shop) => shop.shopName,
                optionsBuilder: (value) {
                  final query = value.text.trim().toLowerCase();
                  if (query.isEmpty) return _shops;
                  return _shops.where((shop) => shop.shopName.toLowerCase().contains(query));
                },
                onSelected: (shop) => setState(() {
                  _selectedShopId = shop.shopId;
                  _suppressShopListener = true;
                  _shopController.text = shop.shopName;
                  _suppressShopListener = false;
                  _previewData = null;
                }),
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(labelText: 'Shop'),
                  );
                },
              ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Settlement Date', suffixIcon: Icon(Icons.calendar_today)),
                child: Text(dateFormat.format(_settlementDate)),
              ),
            ),
            if (preview != null) ...[
              const SizedBox(height: 16),
              Text(preview.shopName ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
              Text('Pending rows: ${preview.pendingCount}'),
              Text('Total pending: ${currency.format(preview.pendingTotal)}'),
              const SizedBox(height: 8),
              const Text(
                "Cash was already received daily, so no additional cash is booked. This creates one credit on the shop ledger.",
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        OutlinedButton(
          onPressed: (_selectedShopId == null || _previewing) ? null : _loadPreview,
          child: _previewing
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Preview'),
        ),
        FilledButton(
          onPressed: (preview == null || _settling) ? null : _confirm,
          child: _settling
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Confirm'),
        ),
      ],
    );
  }
}
