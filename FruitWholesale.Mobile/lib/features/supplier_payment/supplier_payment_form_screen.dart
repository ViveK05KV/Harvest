import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/lookup_service.dart';
import '../../core/models/supplier_option.dart';
import 'supplier_payment_models.dart';
import 'supplier_payment_service.dart';

class SupplierPaymentFormScreen extends StatefulWidget {
  final int? paymentId;

  const SupplierPaymentFormScreen({super.key, this.paymentId});

  bool get isEditing => paymentId != null;

  @override
  State<SupplierPaymentFormScreen> createState() => _SupplierPaymentFormScreenState();
}

class _SupplierPaymentFormScreenState extends State<SupplierPaymentFormScreen> {
  late final SupplierPaymentService _paymentService = SupplierPaymentService(context.read<ApiClient>());
  late final LookupService _lookupService = LookupService(context.read<ApiClient>());

  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _discountController = TextEditingController(text: '0');
  final _referenceController = TextEditingController();
  final _remarksController = TextEditingController();

  List<SupplierOption> _suppliers = [];
  int? _selectedSupplierId;
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
    _discountController.dispose();
    _referenceController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final suppliers = await _lookupService.getActiveSuppliers();

      if (widget.isEditing) {
        final payment = await _paymentService.getById(widget.paymentId!);
        _selectedSupplierId = payment.supplierId;
        _date = payment.paymentDate;
        _amountController.text = _trimZeros(payment.amountPaid);
        _discountController.text = _trimZeros(payment.discountAmount);
        _paymentMode = payment.paymentMode;
        _referenceController.text = payment.referenceNumber ?? '';
        _remarksController.text = payment.remarks ?? '';
      }

      setState(() => _suppliers = suppliers);
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
    if (_selectedSupplierId == null) {
      setState(() => _error = 'Select a supplier.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final payment = SupplierPayment(
      paymentDate: _date,
      supplierId: _selectedSupplierId!,
      amountPaid: double.tryParse(_amountController.text) ?? 0,
      discountAmount: double.tryParse(_discountController.text) ?? 0,
      paymentMode: _paymentMode,
      referenceNumber: _referenceController.text.trim().isEmpty ? null : _referenceController.text.trim(),
      remarks: _remarksController.text.trim().isEmpty ? null : _remarksController.text.trim(),
    );

    try {
      if (widget.isEditing) {
        await _paymentService.update(widget.paymentId!, payment);
      } else {
        await _paymentService.create(payment);
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
      appBar: AppBar(title: Text(widget.isEditing ? 'Edit Supplier Payment' : 'New Supplier Payment')),
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
            initialValue: _selectedSupplierId,
            decoration: const InputDecoration(labelText: 'Supplier'),
            items: [
              for (final supplier in _suppliers) DropdownMenuItem(value: supplier.supplierId, child: Text(supplier.supplierName)),
            ],
            onChanged: (value) => setState(() => _selectedSupplierId = value),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _amountController,
            decoration: const InputDecoration(labelText: 'Amount Paid'),
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
              labelText: 'Discount Received',
              helperText: 'Optional — reduces the supplier\'s outstanding in addition to the amount paid',
              helperMaxLines: 2,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
