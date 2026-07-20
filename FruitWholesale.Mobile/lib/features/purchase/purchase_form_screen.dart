import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/lookup_service.dart';
import '../../core/models/fruit_option.dart';
import '../../core/models/supplier_option.dart';
import 'purchase_models.dart';
import 'purchase_service.dart';

class PurchaseFormScreen extends StatefulWidget {
  final int? purchaseId;

  const PurchaseFormScreen({super.key, this.purchaseId});

  bool get isEditing => purchaseId != null;

  @override
  State<PurchaseFormScreen> createState() => _PurchaseFormScreenState();
}

class _LineItemForm {
  int? fruitId;
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  double get quantity => double.tryParse(quantityController.text) ?? 0;
  double get price => double.tryParse(priceController.text) ?? 0;
  double get amount => quantity * price;

  void dispose() {
    quantityController.dispose();
    priceController.dispose();
  }
}

class _PurchaseFormScreenState extends State<PurchaseFormScreen> {
  late final PurchaseService _purchaseService = PurchaseService(context.read<ApiClient>());
  late final LookupService _lookupService = LookupService(context.read<ApiClient>());

  final _formKey = GlobalKey<FormState>();
  final _invoiceNoController = TextEditingController();
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
      final suppliers = await _lookupService.getActiveSuppliers();
      final fruits = await _lookupService.getActiveFruits();

      if (widget.isEditing) {
        final detail = await _purchaseService.getById(widget.purchaseId!);
        _selectedSupplierId = detail.supplierId;
        _date = detail.purchaseDate;
        _invoiceNoController.text = detail.invoiceNo;
        _remarksController.text = detail.remarks ?? '';
        _items
          ..clear()
          ..addAll(detail.items.map((i) {
            final form = _LineItemForm()..fruitId = i.fruitId;
            form.quantityController.text = _trimZeros(i.quantity);
            form.priceController.text = _trimZeros(i.purchasePrice);
            return form;
          }));
        if (_items.isEmpty) _items.add(_LineItemForm());
      } else {
        _invoiceNoController.text = await _purchaseService.getNextInvoiceNo();
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

  String _trimZeros(double value) {
    return value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toString();
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _date = picked);
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

    final purchase = PurchaseDetail(
      purchaseDate: _date,
      supplierId: _selectedSupplierId!,
      invoiceNo: _invoiceNoController.text.trim(),
      remarks: _remarksController.text.trim().isEmpty ? null : _remarksController.text.trim(),
      items: validItems.map((i) => PurchaseItem(fruitId: i.fruitId!, quantity: i.quantity, purchasePrice: i.price)).toList(),
    );

    try {
      if (widget.isEditing) {
        await _purchaseService.update(widget.purchaseId!, purchase);
      } else {
        await _purchaseService.create(purchase);
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
      appBar: AppBar(title: Text(widget.isEditing ? 'Edit Purchase' : 'New Purchase')),
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
    final scheme = Theme.of(context).colorScheme;
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_error != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: scheme.errorContainer, borderRadius: BorderRadius.circular(8)),
              child: Text(_error!, style: TextStyle(color: scheme.onErrorContainer)),
            ),
            const SizedBox(height: 16),
          ],
          TextFormField(
            controller: _invoiceNoController,
            decoration: const InputDecoration(labelText: 'Invoice Number'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Invoice number is required' : null,
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _pickDate,
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'Date', suffixIcon: Icon(Icons.calendar_today)),
              child: Text(DateFormat('dd-MMM-yyyy').format(_date)),
            ),
          ),
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
                IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _removeRow(index)),
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
                    controller: item.priceController,
                    decoration: const InputDecoration(labelText: 'Purchase Price'),
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
      decoration: BoxDecoration(color: scheme.surface, border: Border(top: BorderSide(color: scheme.outlineVariant))),
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
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save),
              label: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
