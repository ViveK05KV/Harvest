import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import 'fruit_master_models.dart';
import 'fruit_master_service.dart';

class FruitMasterFormScreen extends StatefulWidget {
  final int? fruitId;

  const FruitMasterFormScreen({super.key, this.fruitId});

  bool get isEditing => fruitId != null;

  @override
  State<FruitMasterFormScreen> createState() => _FruitMasterFormScreenState();
}

class _FruitMasterFormScreenState extends State<FruitMasterFormScreen> {
  late final FruitMasterService _service = FruitMasterService(context.read<ApiClient>());

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _unitController = TextEditingController();

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
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final fruit = await _service.getById(widget.fruitId!);
      _nameController.text = fruit.fruitName;
      _unitController.text = fruit.unit;
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
    final fruit = FruitMaster(fruitName: _nameController.text.trim(), unit: _unitController.text.trim());
    try {
      if (widget.isEditing) {
        await _service.update(widget.fruitId!, fruit);
      } else {
        await _service.create(fruit);
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
      appBar: AppBar(title: Text(widget.isEditing ? 'Edit Fruit' : 'New Fruit')),
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
                    decoration: const InputDecoration(labelText: 'Fruit Name'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Fruit name is required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _unitController,
                    decoration: const InputDecoration(labelText: 'Unit', helperText: 'e.g. kg, box, dozen'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Unit is required' : null,
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
