import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import 'supplier_master_models.dart';
import 'supplier_master_service.dart';

class SupplierMasterFormScreen extends StatefulWidget {
  final int? supplierId;

  const SupplierMasterFormScreen({super.key, this.supplierId});

  bool get isEditing => supplierId != null;

  @override
  State<SupplierMasterFormScreen> createState() => _SupplierMasterFormScreenState();
}

class _SupplierMasterFormScreenState extends State<SupplierMasterFormScreen> {
  late final SupplierMasterService _service = SupplierMasterService(context.read<ApiClient>());

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _openingBalanceController = TextEditingController(text: '0');

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
    _phoneController.dispose();
    _addressController.dispose();
    _openingBalanceController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final supplier = await _service.getById(widget.supplierId!);
      _nameController.text = supplier.supplierName;
      _phoneController.text = supplier.phone ?? '';
      _addressController.text = supplier.address ?? '';
      _openingBalanceController.text = supplier.openingBalance.toStringAsFixed(2);
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

    final supplier = SupplierMaster(
      supplierName: _nameController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      openingBalance: double.tryParse(_openingBalanceController.text) ?? 0,
    );

    try {
      if (widget.isEditing) {
        await _service.update(widget.supplierId!, supplier);
      } else {
        await _service.create(supplier);
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
      appBar: AppBar(title: Text(widget.isEditing ? 'Edit Supplier' : 'New Supplier')),
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
                    decoration: const InputDecoration(labelText: 'Supplier Name'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Supplier name is required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'Phone'),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(labelText: 'Address'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  if (!widget.isEditing)
                    TextFormField(
                      controller: _openingBalanceController,
                      decoration: const InputDecoration(labelText: 'Opening Balance'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
