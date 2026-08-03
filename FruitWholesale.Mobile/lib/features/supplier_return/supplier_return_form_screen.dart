import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/lookup_service.dart';
import '../../core/models/fruit_option.dart';
import '../../core/models/supplier_option.dart';
import '../../core/utils/number_format_utils.dart';
import '../../core/widgets/date_picker_field.dart';
import '../../core/widgets/error_banner.dart';
import '../../core/widgets/save_button.dart';
import 'supplier_return_models.dart';
import 'supplier_return_service.dart';

class SupplierReturnFormScreen extends StatefulWidget {
  /// Null means "create new"; otherwise the existing return being edited.
  final int? supplierReturnId;

  const SupplierReturnFormScreen({super.key, this.supplierReturnId});

  bool get isEditing => supplierReturnId != null;

  @override
  State<SupplierReturnFormScreen> createState() => _SupplierReturnFormScreenState();
}

class _LineItemForm {
  int? fruitId;
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController unitPriceController = TextEditingController();
  final TextEditingController boxCountController = TextEditingController();

  double get quantity => double.tryParse(quantityController.text) ?? 0;
  double get unitPrice => double.tryParse(unitPriceController.text) ?? 0;
  double? get boxCount => double.tryParse(boxCountController.text);
  double get amount => (boxCount != null && boxCount! > 0) ? boxCount! * unitPrice : quantity * unitPrice;

  void dispose() {
    quantityController.dispose();
    unitPriceController.dispose();
    boxCountController.dispose();
  }
}

class _SupplierReturnFormScreenState extends State<SupplierReturnFormScreen> {
  late final SupplierReturnService _supplierReturnService = SupplierReturnService(context.read<ApiClient>());
  late final LookupService _lookupService = LookupService(context.read<ApiClient>());

  final _formKey = GlobalKey<FormState>();
  final _referenceNoController = TextEditingController();
  final _remarksController = TextEditingController();

  List<SupplierOption> _suppliers = [];
  List<FruitOption> _fruits = [];
  int? _selectedSupplierId;
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
    _referenceNoController.dispose();
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
      final suppliersFuture = _lookupService.getActiveSuppliers();
      final fruitsFuture = _lookupService.getActiveFruits();
      final suppliers = await suppliersFuture;
      final fruits = await fruitsFuture;

      if (widget.isEditing) {
        final detail = await _supplierReturnService.getById(widget.supplierReturnId!);
        _selectedSupplierId = detail.supplierId;
        _date = detail.returnDate;
        _referenceNoController.text = detail.referenceNo;
        _remarksController.text = detail.remarks ?? '';
        _items
          ..clear()
          ..addAll(detail.items.map((i) {
            final form = _LineItemForm()..fruitId = i.fruitId;
            form.quantityController.text = trimZeros(i.quantity);
            form.unitPriceController.text = trimZeros(i.unitPrice);
            if (i.boxCount != null) form.boxCountController.text = '${i.boxCount}';
            return form;
          }));
        if (_items.isEmpty) _items.add(_LineItemForm());
      } else {
        _referenceNoController.text = await _supplierReturnService.getNextReferenceNo();
      }

      setState(() {
        _suppliers = suppliers;
        _fruits = fruits;
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  double get _grandTotal => _items.fold(0, (sum, item) => sum + item.amount);

  FruitOption? _findFruit(int? fruitId) {
    for (final fruit in _fruits) {
      if (fruit.fruitId == fruitId) return fruit;
    }
    return null;
  }

  bool _fruitTracksByBox(int? fruitId) => _findFruit(fruitId)?.tracksByBox ?? false;

  double? _fruitBoxWeight(int? fruitId) => _findFruit(fruitId)?.boxWeightKg;

  void _onBoxCountChanged(_LineItemForm item) {
    final boxWeight = _fruitBoxWeight(item.fruitId);
    final boxCount = item.boxCount;
    if (boxWeight != null && boxCount != null && boxCount > 0) {
      setState(() => item.quantityController.text = trimZeros(boxWeight * boxCount));
    } else {
      setState(() {});
    }
  }

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
    if (_selectedSupplierId == null) {
      setState(() => _error = 'Select a supplier.');
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

    final supplierReturn = SupplierReturnDetail(
      returnDate: _date,
      supplierId: _selectedSupplierId!,
      referenceNo: _referenceNoController.text.trim(),
      remarks: _remarksController.text.trim().isEmpty ? null : _remarksController.text.trim(),
      items: validItems
          .map((i) => SupplierReturnItem(
                fruitId: i.fruitId!,
                quantity: i.quantity,
                unitPrice: i.unitPrice,
                boxCount: _fruitTracksByBox(i.fruitId) ? i.boxCount : null,
              ))
          .toList(),
    );

    try {
      if (widget.isEditing) {
        await _supplierReturnService.update(widget.supplierReturnId!, supplierReturn);
      } else {
        await _supplierReturnService.create(supplierReturn);
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
      appBar: AppBar(title: Text(widget.isEditing ? 'Edit Supplier Return' : 'New Supplier Return')),
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
            controller: _referenceNoController,
            decoration: const InputDecoration(labelText: 'Reference Number'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Reference number is required' : null,
          ),
          const SizedBox(height: 16),
          DatePickerField(date: _date, onChanged: (picked) => setState(() => _date = picked)),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            initialValue: _selectedSupplierId,
            decoration: const InputDecoration(labelText: 'Supplier'),
            items: [
              for (final supplier in _suppliers) DropdownMenuItem(value: supplier.supplierId, child: Text(supplier.supplierName)),
            ],
            onChanged: (value) => setState(() => _selectedSupplierId = value),
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
            if (_fruitTracksByBox(item.fruitId)) ...[
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: item.boxCountController,
                      decoration: const InputDecoration(labelText: 'Box Count'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => _onBoxCountChanged(item),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _fruitBoxWeight(item.fruitId) != null
                        ? Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text('= ${trimZeros(item.quantity)} kg', style: const TextStyle(fontSize: 13)),
                          )
                        : TextFormField(
                            controller: item.quantityController,
                            decoration: const InputDecoration(labelText: 'Quantity (kg)'),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (_) => setState(() {}),
                          ),
                  ),
                ],
              ),
            ] else
              TextFormField(
                controller: item.quantityController,
                decoration: const InputDecoration(labelText: 'Quantity'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
              ),
            const SizedBox(height: 12),
            TextFormField(
              controller: item.unitPriceController,
              decoration: InputDecoration(
                labelText: 'Rate',
                suffixText: (_fruitTracksByBox(item.fruitId) && item.boxCount != null) ? '/box' : '/kg',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Amount: ${NumberFormat.currency(locale: 'en_IN', symbol: 'â‚¹').format(item.amount)}',
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
                'Grand Total: ${NumberFormat.currency(locale: 'en_IN', symbol: 'â‚¹').format(_grandTotal)}',
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