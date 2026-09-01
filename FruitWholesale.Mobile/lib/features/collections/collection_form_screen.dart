import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/number_format_utils.dart';
import '../../core/widgets/date_picker_field.dart';
import '../../core/widgets/error_banner.dart';
import '../../core/widgets/save_footer_bar.dart';
import '../ledgers/ledger_models.dart';
import '../ledgers/ledger_service.dart';
import '../shop_master/shop_master_models.dart';
import '../shop_master/shop_master_service.dart';
import 'collection_models.dart';
import 'collection_service.dart';

// Mirrors collection-form.component.scss's quickAmounts exactly.
const _kQuickAmounts = [500, 1000, 2000, 5000, 10000];

const _kSummaryMuted = Color(0xFF8BA899); // .shop-summary-row
const _kSummaryText = AppColors.sidebarText; // .shop-summary strong (#e6ece7)
const _kSummaryReceiving = Color(0xFF7FD6A0); // .shop-summary-row .receiving
const _kActivityMuted = Color(0xFF9AA39C); // .activity-date / .muted

class CollectionFormScreen extends StatefulWidget {
  final int? collectionId;

  const CollectionFormScreen({super.key, this.collectionId});

  bool get isEditing => collectionId != null;

  @override
  State<CollectionFormScreen> createState() => _CollectionFormScreenState();
}

class _CollectionFormScreenState extends State<CollectionFormScreen> {
  late final CollectionService _collectionService = CollectionService(context.read<ApiClient>());
  late final ShopMasterService _shopService = ShopMasterService(context.read<ApiClient>());
  late final LedgerService _ledgerService = LedgerService(context.read<ApiClient>());

  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _discountController = TextEditingController(text: '0');
  final _referenceController = TextEditingController();
  final _remarksController = TextEditingController();
  final _shopController = TextEditingController();
  final _shopFocusNode = FocusNode();

  List<ShopMaster> _shops = [];
  int? _selectedShopId;
  DateTime _date = DateTime.now();
  String _paymentMode = paymentModes.first;
  bool _isTemporary = false;
  bool _isSettled = false;

  List<LedgerEntry> _recentActivity = [];
  bool _activityLoading = false;

  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Amount/discount drive the live "receiving"/"balance after" preview.
    _amountController.addListener(_refreshPreview);
    _discountController.addListener(_refreshPreview);
    _load();
  }

  void _refreshPreview() => setState(() {});

  @override
  void dispose() {
    _amountController.dispose();
    _discountController.dispose();
    _referenceController.dispose();
    _remarksController.dispose();
    _shopController.dispose();
    _shopFocusNode.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final shops = await _shopService.getAllActive();

      if (widget.isEditing) {
        final collection = await _collectionService.getById(widget.collectionId!);
        _selectedShopId = collection.shopId;
        _date = collection.collectionDate;
        _amountController.text = trimZeros(collection.amountReceived);
        _discountController.text = trimZeros(collection.discountAmount);
        _paymentMode = collection.paymentMode;
        _referenceController.text = collection.referenceNumber ?? '';
        _remarksController.text = collection.remarks ?? '';
        _isTemporary = collection.isTemporary;
        _isSettled = collection.isSettled;
      }

      setState(() {
        _shops = shops;
        _shopController.text = _findShop(_selectedShopId)?.shopName ?? '';
      });
      if (_selectedShopId != null) _loadRecentActivity(_selectedShopId!);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadRecentActivity(int shopId) async {
    setState(() => _activityLoading = true);
    try {
      final result = await _ledgerService.getShopLedger(shopId);
      if (!mounted) return;
      setState(() => _recentActivity = result.items.take(4).toList());
    } on ApiException {
      // Activity panel just stays empty.
    } finally {
      if (mounted) setState(() => _activityLoading = false);
    }
  }

  ShopMaster? _findShop(int? shopId) {
    for (final shop in _shops) {
      if (shop.shopId == shopId) return shop;
    }
    return null;
  }

  double get _receivingTotal => (double.tryParse(_amountController.text) ?? 0) + (double.tryParse(_discountController.text) ?? 0);

  double _balanceAfter(ShopMaster shop) => shop.currentOutstanding - _receivingTotal;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedShopId == null) {
      setState(() => _error = 'Select a shop.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final collection = Collection(
      collectionDate: _date,
      shopId: _selectedShopId!,
      amountReceived: double.tryParse(_amountController.text) ?? 0,
      discountAmount: double.tryParse(_discountController.text) ?? 0,
      paymentMode: _paymentMode,
      referenceNumber: _referenceController.text.trim().isEmpty ? null : _referenceController.text.trim(),
      remarks: _remarksController.text.trim().isEmpty ? null : _remarksController.text.trim(),
      collectionType: _isTemporary ? 'Temporary' : 'Normal',
      temporaryStatus: _isTemporary ? 'Pending' : 'None',
    );

    try {
      if (widget.isEditing) {
        await _collectionService.update(widget.collectionId!, collection);
      } else {
        await _collectionService.create(collection);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isEditing ? 'Edit Collection' : 'New Collection')),
      body: _loading ? const Center(child: CircularProgressIndicator()) : _buildForm(),
      bottomNavigationBar: _loading ? null : SaveFooterBar(saving: _saving, onPressed: _save),
    );
  }

  Widget _buildForm() {
    final shop = _findShop(_selectedShopId);
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_error != null) ...[
            ErrorBanner(_error!),
            const SizedBox(height: 16),
          ],
          DatePickerField(date: _date, onChanged: (picked) => setState(() => _date = picked)),
          const SizedBox(height: 16),
          Autocomplete<ShopMaster>(
            textEditingController: _shopController,
            focusNode: _shopFocusNode,
            displayStringForOption: (shop) => shop.shopName,
            optionsBuilder: (value) {
              final query = value.text.trim().toLowerCase();
              if (query.isEmpty) return _shops;
              return _shops.where((shop) => shop.shopName.toLowerCase().contains(query));
            },
            onSelected: (shop) {
              setState(() {
                _selectedShopId = shop.shopId;
                _shopController.text = shop.shopName;
                _recentActivity = [];
              });
              _loadRecentActivity(shop.shopId);
            },
            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
              return TextFormField(
                controller: controller,
                focusNode: focusNode,
                decoration: const InputDecoration(labelText: 'Shop'),
              );
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _amountController,
            decoration: const InputDecoration(labelText: 'Amount Received'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (v) {
              final amount = double.tryParse(v ?? '');
              if (amount == null || amount <= 0) return 'Enter a valid amount';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _discountController,
            decoration: const InputDecoration(
              labelText: 'Discount Given',
              helperText: 'Optional — reduces the shop\'s outstanding in addition to the amount received',
              helperMaxLines: 2,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final amount in _kQuickAmounts)
                OutlinedButton(
                  onPressed: () => setState(() => _amountController.text = amount.toString()),
                  child: Text('₹${NumberFormat.decimalPattern('en_IN').format(amount)}'),
                ),
            ],
          ),
          if (shop != null) ...[
            const SizedBox(height: 16),
            _ShopSummaryCard(shop: shop, receivingTotal: _receivingTotal, balanceAfter: _balanceAfter(shop)),
            const SizedBox(height: 16),
            _RecentActivityCard(loading: _activityLoading, rows: _recentActivity),
          ],
          const SizedBox(height: 16),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text('Temporary deposit'),
            subtitle: _isTemporary
                ? const Text(
                    'Adds cash today but leaves the shop balance untouched until you settle it.',
                    style: TextStyle(color: AppColors.mutedInk),
                  )
                : null,
            value: _isTemporary,
            onChanged: _isSettled ? null : (value) => setState(() => _isTemporary = value ?? false),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _paymentMode,
            decoration: const InputDecoration(labelText: 'Payment Mode'),
            items: [for (final mode in paymentModes) DropdownMenuItem(value: mode, child: Text(mode))],
            onChanged: (value) => setState(() => _paymentMode = value!),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _referenceController,
            decoration: const InputDecoration(labelText: 'Reference Number'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _remarksController,
            decoration: const InputDecoration(labelText: 'Remarks'),
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

class _ShopSummaryCard extends StatelessWidget {
  const _ShopSummaryCard({required this.shop, required this.receivingTotal, required this.balanceAfter});
  final ShopMaster shop;
  final double receivingTotal;
  final double balanceAfter;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.decimalPattern('en_IN');
    return Card(
      color: AppColors.sidebarBg,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(shop.shopName.toUpperCase(), style: const TextStyle(color: _kSummaryMuted, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 12),
            _row('Outstanding now', currency.format(shop.currentOutstanding), _kSummaryText, 14),
            const SizedBox(height: 8),
            _row('Receiving', '−${currency.format(receivingTotal)}', _kSummaryReceiving, 14),
            const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(color: Colors.white24, height: 1)),
            _row('Balance after', currency.format(balanceAfter), _kSummaryText, 18, bold: true),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, Color valueColor, double valueSize, {bool bold = false}) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(label, style: const TextStyle(color: _kSummaryMuted, fontSize: 12)),
          Text(value, style: TextStyle(color: valueColor, fontSize: valueSize, fontWeight: bold ? FontWeight.w700 : FontWeight.w600)),
        ],
      );
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard({required this.loading, required this.rows});
  final bool loading;
  final List<LedgerEntry> rows;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.decimalPattern('en_IN');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('RECENT ACTIVITY', style: TextStyle(color: AppColors.mutedInk, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 10),
            if (loading)
              const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))))
            else if (rows.isEmpty)
              const Text('No recent activity.', style: TextStyle(color: _kActivityMuted, fontSize: 12))
            else
              for (final row in rows)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(row.narration ?? row.transactionType, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                            Text(DateFormat('dd MMM').format(row.transactionDate), style: const TextStyle(fontSize: 10.5, color: _kActivityMuted)),
                          ],
                        ),
                      ),
                      Text(
                        currency.format(row.debit > 0 ? row.debit : row.credit),
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: row.credit > 0 ? AppColors.primary : AppColors.ink),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
