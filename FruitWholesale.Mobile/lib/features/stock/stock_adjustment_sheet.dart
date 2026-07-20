import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/lookup_service.dart';
import '../../core/models/fruit_option.dart';
import 'stock_service.dart';

class StockAdjustmentSheet extends StatefulWidget {
  const StockAdjustmentSheet({super.key});

  @override
  State<StockAdjustmentSheet> createState() => _StockAdjustmentSheetState();
}

class _StockAdjustmentSheetState extends State<StockAdjustmentSheet> {
  late final StockService _stockService = StockService(context.read<ApiClient>());
  late final LookupService _lookupService = LookupService(context.read<ApiClient>());

  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _narrationController = TextEditingController();

  List<FruitOption> _fruits = [];
  int? _selectedFruitId;
  bool _isIncrease = true;

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
    _quantityController.dispose();
    _narrationController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final fruits = await _lookupService.getActiveFruits();
      setState(() {
        _fruits = fruits;
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFruitId == null) {
      setState(() => _error = 'Select a fruit.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _stockService.applyAdjustment(
        fruitId: _selectedFruitId!,
        quantity: double.tryParse(_quantityController.text) ?? 0,
        isIncrease: _isIncrease,
        narration: _narrationController.text.trim(),
      );
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
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: _loading
          ? const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()))
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Stock Adjustment', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)),
                      ),
                      const SizedBox(height: 16),
                    ],
                    DropdownButtonFormField<int>(
                      initialValue: _selectedFruitId,
                      decoration: const InputDecoration(labelText: 'Fruit'),
                      items: [
                        for (final fruit in _fruits) DropdownMenuItem(value: fruit.fruitId, child: Text(fruit.fruitName)),
                      ],
                      onChanged: (value) => setState(() => _selectedFruitId = value),
                    ),
                    const SizedBox(height: 16),
                    RadioGroup<bool>(
                      groupValue: _isIncrease,
                      onChanged: (v) => setState(() => _isIncrease = v!),
                      child: const Row(
                        children: [
                          Expanded(child: RadioListTile<bool>(title: Text('Increase'), value: true)),
                          Expanded(child: RadioListTile<bool>(title: Text('Decrease'), value: false)),
                        ],
                      ),
                    ),
                    TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(labelText: 'Quantity'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        final qty = double.tryParse(v ?? '');
                        if (qty == null || qty <= 0) return 'Enter a valid quantity';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _narrationController,
                      decoration: const InputDecoration(labelText: 'Reason / Narration'),
                      maxLines: 2,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Narration is required' : null,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save),
                      label: const Text('Apply Adjustment'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
