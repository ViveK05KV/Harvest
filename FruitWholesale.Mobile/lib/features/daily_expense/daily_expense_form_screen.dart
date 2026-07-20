import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/lookup_service.dart';
import '../../core/models/expense_category_option.dart';
import 'daily_expense_models.dart';
import 'daily_expense_service.dart';

class DailyExpenseFormScreen extends StatefulWidget {
  final int? expenseId;

  const DailyExpenseFormScreen({super.key, this.expenseId});

  bool get isEditing => expenseId != null;

  @override
  State<DailyExpenseFormScreen> createState() => _DailyExpenseFormScreenState();
}

class _DailyExpenseFormScreenState extends State<DailyExpenseFormScreen> {
  late final DailyExpenseService _expenseService = DailyExpenseService(context.read<ApiClient>());
  late final LookupService _lookupService = LookupService(context.read<ApiClient>());

  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _paidToController = TextEditingController();
  final _descriptionController = TextEditingController();

  List<ExpenseCategoryOption> _categories = [];
  int? _selectedCategoryId;
  DateTime _date = DateTime.now();
  String _paymentMode = paymentModes.first;

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
    _amountController.dispose();
    _paidToController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final categories = await _lookupService.getActiveExpenseCategories();

      if (widget.isEditing) {
        final expense = await _expenseService.getById(widget.expenseId!);
        _selectedCategoryId = expense.expenseCategoryId;
        _date = expense.expenseDate;
        _amountController.text = _trimZeros(expense.amount);
        _paymentMode = expense.paymentMode;
        _paidToController.text = expense.paidTo ?? '';
        _descriptionController.text = expense.description ?? '';
      }

      setState(() => _categories = categories);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  String _trimZeros(double value) {
    return value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toString();
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
    if (_selectedCategoryId == null) {
      setState(() => _error = 'Select an expense category.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final expense = DailyExpense(
      expenseDate: _date,
      expenseCategoryId: _selectedCategoryId!,
      amount: double.tryParse(_amountController.text) ?? 0,
      paymentMode: _paymentMode,
      paidTo: _paidToController.text.trim().isEmpty ? null : _paidToController.text.trim(),
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
    );

    try {
      if (widget.isEditing) {
        await _expenseService.update(widget.expenseId!, expense);
      } else {
        await _expenseService.create(expense);
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
      appBar: AppBar(title: Text(widget.isEditing ? 'Edit Expense' : 'New Expense')),
      body: _loading ? const Center(child: CircularProgressIndicator()) : _buildForm(),
      bottomNavigationBar: _loading ? null : _buildFooter(),
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
          InkWell(
            onTap: _pickDate,
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'Date', suffixIcon: Icon(Icons.calendar_today)),
              child: Text(DateFormat('dd-MMM-yyyy').format(_date)),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            initialValue: _selectedCategoryId,
            decoration: const InputDecoration(labelText: 'Expense Category'),
            items: [
              for (final category in _categories)
                DropdownMenuItem(value: category.expenseCategoryId, child: Text(category.categoryName)),
            ],
            onChanged: (value) => setState(() => _selectedCategoryId = value),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _amountController,
            decoration: const InputDecoration(labelText: 'Amount'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (v) {
              final amount = double.tryParse(v ?? '');
              if (amount == null || amount <= 0) return 'Enter a valid amount';
              return null;
            },
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
            controller: _paidToController,
            decoration: const InputDecoration(labelText: 'Paid To'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(labelText: 'Description'),
            maxLines: 2,
          ),
        ],
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
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save),
            label: const Text('Save'),
          ),
        ),
      ),
    );
  }
}
