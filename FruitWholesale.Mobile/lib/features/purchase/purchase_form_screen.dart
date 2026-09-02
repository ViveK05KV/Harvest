import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/lookup_service.dart';
import '../../core/auth/auth_service.dart';
import '../../core/models/fruit_option.dart';
import '../../core/models/supplier_option.dart';
import '../../core/models/user_role.dart';
import '../../core/utils/number_format_utils.dart';
import '../../core/widgets/date_picker_field.dart';
import '../../core/widgets/error_banner.dart';
import '../../core/widgets/save_button.dart';
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
  String saleType = 'kg';
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController boxCountController = TextEditingController();
  final TextEditingController fruitController = TextEditingController();
  final FocusNode fruitFocusNode = FocusNode();

  double get quantity => double.tryParse(quantityController.text) ?? 0;
  double get price => double.tryParse(priceController.text) ?? 0;
  double? get boxCount => double.tryParse(boxCountController.text);
  double get amount => (saleType == 'box' && boxCount != null) ? boxCount! * price : quantity * price;

  void dispose() {
    quantityController.dispose();
    priceController.dispose();
    boxCountController.dispose();
    fruitController.dispose();
    fruitFocusNode.dispose();
  }
}

class _PurchaseFormScreenState extends State<PurchaseFormScreen> {
  late final PurchaseService _purchaseService = PurchaseService(context.read<ApiClient>());
  late final LookupService _lookupService = LookupService(context.read<ApiClient>());

  final _formKey = GlobalKey<FormState>();
  final _invoiceNoController = TextEditingController();
  final _remarksController = TextEditingController();
  final _supplierController = TextEditingController();
  final _supplierFocusNode = FocusNode();

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
    _supplierController.dispose();
    _supplierFocusNode.dispose();
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
        final detail = await _purchaseService.getById(widget.purchaseId!);
        _selectedSupplierId = detail.supplierId;
        _date = detail.purchaseDate;
        _invoiceNoController.text = detail.invoiceNo;
        _remarksController.text = detail.remarks ?? '';
        _items
          ..clear()
          ..addAll(detail.items.map((i) {
            final form = _LineItemForm()..fruitId = i.fruitId;
            form.quantityController.text = trimZeros(i.quantity);
            form.priceController.text = trimZeros(i.purchasePrice);
            if (i.boxCount != null) {
              form.saleType = 'box';
              form.boxCountController.text = '${i.boxCount}';
            }
            return form;
          }));
        if (_items.isEmpty) _items.add(_LineItemForm());
      } else {
        _invoiceNoController.text = await _purchaseService.getNextInvoiceNo();
      }

      setState(() {
        _suppliers = suppliers;
        _fruits = fruits;
        _supplierController.text = _findSupplier(_selectedSupplierId)?.supplierName ?? '';
        for (final item in _items) {
          item.fruitController.text = _findFruit(item.fruitId)?.fruitName ?? '';
        }
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

  SupplierOption? _findSupplier(int? supplierId) {
    for (final supplier in _suppliers) {
      if (supplier.supplierId == supplierId) return supplier;
    }
    return null;
  }

  bool _fruitTracksByBox(int? fruitId) => _findFruit(fruitId)?.tracksByBox ?? false;

  double? _fruitBoxWeight(int? fruitId) => _findFruit(fruitId)?.boxWeightKg;

  bool get _isAdmin => context.read<AuthService>().user?.role == UserRole.admin;

  void _onBoxCountChanged(_LineItemForm item) {
    final boxWeight = _fruitBoxWeight(item.fruitId);
    final boxCount = item.boxCount;
    if (boxWeight != null && boxCount != null && boxCount > 0) {
      setState(() => item.quantityController.text = trimZeros(boxWeight * boxCount));
    } else {
      setState(() {});
    }
  }

  // Admin-only: back-solve Rate from a typed Amount (Rate = Amount / effective
  // quantity) instead of the usual Rate-in, Amount-out direction.
  Future<void> _editAmount(_LineItemForm item) async {
    final controller = TextEditingController(text: trimZeros(item.amount));
    final entered = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Amount'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(prefixText: '₹'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(double.tryParse(controller.text)),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (entered == null || entered <= 0) return;
    final divisor = (_fruitTracksByBox(item.fruitId) && item.saleType == 'box') ? item.boxCount : item.quantity;
    if (divisor == null || divisor <= 0) return;
    setState(() => item.priceController.text = trimZeros((entered / divisor * 100).round() / 100));
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

    final purchase = PurchaseDetail(
      purchaseDate: _date,
      supplierId: _selectedSupplierId!,
      invoiceNo: _invoiceNoController.text.trim(),
      remarks: _remarksController.text.trim().isEmpty ? null : _remarksController.text.trim(),
      items: validItems
          .map((i) => PurchaseItem(
                fruitId: i.fruitId!,
                quantity: i.quantity,
                purchasePrice: i.price,
                boxCount: (_fruitTracksByBox(i.fruitId) && i.saleType == 'box') ? i.boxCount : null,
              ))
          .toList(),
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
          Autocomplete<SupplierOption>(
            textEditingController: _supplierController,
            focusNode: _supplierFocusNode,
            displayStringForOption: (supplier) => supplier.supplierName,
            optionsBuilder: (value) {
              final query = value.text.trim().toLowerCase();
              if (query.isEmpty) return _suppliers;
              return _suppliers.where((supplier) => supplier.supplierName.toLowerCase().contains(query));
            },
            onSelected: (supplier) => setState(() {
              _selectedSupplierId = supplier.supplierId;
              _supplierController.text = supplier.supplierName;
            }),
            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
              return TextFormField(
                controller: controller,
                focusNode: focusNode,
                decoration: const InputDecoration(labelText: 'Supplier'),
              );
            },
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
      key: ValueKey(item),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Autocomplete<FruitOption>(
                    textEditingController: item.fruitController,
                    focusNode: item.fruitFocusNode,
                    displayStringForOption: (fruit) => fruit.fruitName,
                    optionsBuilder: (value) {
                      final query = value.text.trim().toLowerCase();
                      if (query.isEmpty) return _fruits;
                      return _fruits.where((fruit) => fruit.fruitName.toLowerCase().contains(query));
                    },
                    onSelected: (fruit) => setState(() {
                      item.fruitId = fruit.fruitId;
                      item.fruitController.text = fruit.fruitName;
                      item.saleType = 'kg';
                      item.boxCountController.clear();
                    }),
                    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                      return TextFormField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: const InputDecoration(labelText: 'Fruit'),
                      );
                    },
                  ),
                ),
                IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _removeRow(index)),
              ],
            ),
            if (_fruitTracksByBox(item.fruitId)) ...[
              DropdownButtonFormField<String>(
                initialValue: item.saleType,
                decoration: const InputDecoration(labelText: 'Sell By'),
                items: const [
                  DropdownMenuItem(value: 'kg', child: Text('By Kg')),
                  DropdownMenuItem(value: 'box', child: Text('By Box')),
                ],
                onChanged: (value) => setState(() => item.saleType = value ?? 'kg'),
              ),
              const SizedBox(height: 12),
              if (item.saleType == 'box')
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: item.boxCountController,
                        decoration: const InputDecoration(labelText: 'Boxes'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => _onBoxCountChanged(item),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text('= ${trimZeros(item.quantity)} kg', style: const TextStyle(fontSize: 13)),
                      ),
                    ),
                  ],
                )
              else
                TextFormField(
                  controller: item.quantityController,
                  decoration: const InputDecoration(labelText: 'Quantity (kg)'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
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
              controller: item.priceController,
              decoration: InputDecoration(
                labelText: 'Purchase Price',
                suffixText: (_fruitTracksByBox(item.fruitId) && item.saleType == 'box') ? '/box' : '/kg',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: _isAdmin
                  ? InkWell(
                      onTap: () => _editAmount(item),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        child: Text(
                          'Amount: ${NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(item.amount)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                            decorationStyle: TextDecorationStyle.dotted,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    )
                  : Text(
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
            SaveButton(saving: _saving, onPressed: _save),
          ],
        ),
      ),
    );
  }
}