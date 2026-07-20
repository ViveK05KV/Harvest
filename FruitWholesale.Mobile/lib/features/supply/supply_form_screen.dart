import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/lookup_service.dart';
import '../../core/models/fruit_option.dart';
import '../../core/models/shop_option.dart';
import '../../core/utils/number_format_utils.dart';
import '../../core/widgets/date_picker_field.dart';
import '../../core/widgets/error_banner.dart';
import '../../core/widgets/save_button.dart';
import 'supply_models.dart';
import 'supply_service.dart';

class SupplyFormScreen extends StatefulWidget {
  /// Null means "create new"; otherwise the existing invoice being edited.
  final int? supplyId;

  const SupplyFormScreen({super.key, this.supplyId});

  bool get isEditing => supplyId != null;

  @override
  State<SupplyFormScreen> createState() => _SupplyFormScreenState();
}

class _LineItemForm {
  int? fruitId;
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController unitPriceController = TextEditingController();

  double get quantity => double.tryParse(quantityController.text) ?? 0;
  double get unitPrice => double.tryParse(unitPriceController.text) ?? 0;
  double get amount => quantity * unitPrice;

  void dispose() {
    quantityController.dispose();
    unitPriceController.dispose();
  }
}

class _SupplyFormScreenState extends State<SupplyFormScreen> {
  late final SupplyService _supplyService = SupplyService(context.read<ApiClient>());
  late final LookupService _lookupService = LookupService(context.read<ApiClient>());

  final _formKey = GlobalKey<FormState>();
  final _invoiceNoController = TextEditingController();
  final _remarksController = TextEditingController();

  List<ShopOption> _shops = [];
  List<FruitOption> _fruits = [];
  int? _selectedShopId;
  DateTime _date = DateTime.now();
  final List<_LineItemForm> _items = [_LineItemForm()];

  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _invoiceNoController.dispose();
    _remarksController.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final shops = await _lookupService.getActiveShops();
      final fruits = await _lookupService.getActiveFruits();

      if (widget.isEditing) {
        final detail = await _supplyService.getById(widget.supplyId!);
        _selectedShopId = detail.shopId;
        _date = detail.supplyDate;
        _invoiceNoController.text = detail.invoiceNo;
        _remarksController.text = detail.remarks ?? '';
        _items
          ..clear()
          ..addAll(detail.items.map((i) {
            final form = _LineItemForm()..fruitId = i.fruitId;
            form.quantityController.text = trimZeros(i.quantity);
            form.unitPriceController.text = trimZeros(i.unitPrice);
            return form;
          }));
        if (_items.isEmpty) _items.add(_LineItemForm());
      } else {
        _invoiceNoController.text = await _supplyService.getNextInvoiceNo();
      }

      setState(() {
        _shops = shops;
        _fruits = fruits;
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  double get _grandTotal => _items.fold(0, (sum, item) => sum + item.amount);

  void _addRow() => setState(() => _items.add(_LineItemForm()));

  void _removeRow(int index) {
    setState(() {
      _items[index].dispose();
      _items.removeAt(index);
      if (_items.isEmpty) _items.add(_LineItemForm());
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedShopId == null) {
      setState(() => _error = 'Select a customer (shop).');
      return;
    }
    final validItems = _items.where((i) => i.fruitId != null && i.quantity > 0).toList();
    if (validItems.isEmpty) {
      setState(() => _error = 'Add at least one item with a fruit and quantity.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final supply = SupplyDetail(
      supplyDate: _date,
      shopId: _selectedShopId!,
      invoiceNo: _invoiceNoController.text.trim(),
      remarks: _remarksController.text.trim().isEmpty ? null : _remarksController.text.trim(),
      items: validItems
          .map((i) => SupplyItem(fruitId: i.fruitId!, quantity: i.quantity, unitPrice: i.unitPrice))
          .toList(),
    );

    try {
      if (widget.isEditing) {
        await _supplyService.update(widget.supplyId!, supply);
      } else {
        await _supplyService.create(supply);
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
      appBar: AppBar(title: Text(widget.isEditing ? 'Edit Supply' : 'New Supply')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  Expanded(child: _buildForm()),
                  _buildFooter(),
                ],
              ),
            ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_error != null) ...[
            ErrorBanner(_error!),
            const SizedBox(height: 16),
          ],
          TextFormField(
            controller: _invoiceNoController,
            decoration: const InputDecoration(labelText: 'Invoice Number'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Invoice number is required' : null,
          ),
          const SizedBox(height: 16),
          DatePickerField(date: _date, onChanged: (picked) => setState(() => _date = picked)),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            initialValue: _selectedShopId,
            decoration: const InputDecoration(labelText: 'Customer (Shop)'),
            items: [
              for (final shop in _shops) DropdownMenuItem(value: shop.shopId, child: Text(shop.shopName)),
            ],
            onChanged: (value) => setState(() => _selectedShopId = value),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _remarksController,
            decoration: const InputDecoration(labelText: 'Remarks'),
            maxLines: 2,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Items', style: Theme.of(context).textTheme.titleMedium),
              TextButton.icon(onPressed: _addRow, icon: const Icon(Icons.add), label: const Text('Add Row')),
            ],
          ),
          const SizedBox(height: 8),
          for (int i = 0; i < _items.length; i++) _buildItemRow(i),
        ],
      ),
    );
  }

  Widget _buildItemRow(int index) {
    final item = _items[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: item.fruitId,
                    decoration: const InputDecoration(labelText: 'Fruit'),
                    items: [
                      for (final fruit in _fruits)
                        DropdownMenuItem(value: fruit.fruitId, child: Text('${fruit.fruitName} (${fruit.unit})')),
                    ],
                    onChanged: (value) => setState(() => item.fruitId = value),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _removeRow(index),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: item.quantityController,
                    decoration: const InputDecoration(labelText: 'Quantity'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: item.unitPriceController,
                    decoration: const InputDecoration(labelText: 'Rate'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Amount: ${NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(item.amount)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Grand Total: ${NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(_grandTotal)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            SaveButton(saving: _saving, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
