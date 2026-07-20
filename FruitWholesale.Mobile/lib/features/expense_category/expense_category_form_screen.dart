import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import 'expense_category_models.dart';
import 'expense_category_service.dart';

class ExpenseCategoryFormScreen extends StatefulWidget {
  final int? expenseCategoryId;

  const ExpenseCategoryFormScreen({super.key, this.expenseCategoryId});

  bool get isEditing => expenseCategoryId != null;

  @override
  State<ExpenseCategoryFormScreen> createState() => _ExpenseCategoryFormScreenState();
}

class _ExpenseCategoryFormScreenState extends State<ExpenseCategoryFormScreen> {
  late final ExpenseCategoryService _service = ExpenseCategoryService(context.read<ApiClient>());

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _loading = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final category = await _service.getById(widget.expenseCategoryId!);
      _nameController.text = category.categoryName;
      _descriptionController.text = category.description ?? '';
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final category = ExpenseCategory(
      categoryName: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
    );
    try {
      if (widget.isEditing) {
        await _service.update(widget.expenseCategoryId!, category);
      } else {
        await _service.create(category);
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
      appBar: AppBar(title: Text(widget.isEditing ? 'Edit Expense Category' : 'New Expense Category')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
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
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Category Name'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Category name is required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),
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
