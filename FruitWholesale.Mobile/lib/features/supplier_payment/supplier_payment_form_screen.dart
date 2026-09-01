import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/lookup_service.dart';
import '../../core/models/supplier_option.dart';
import '../../core/utils/number_format_utils.dart';
import '../../core/widgets/date_picker_field.dart';
import '../../core/widgets/error_banner.dart';
import '../../core/widgets/save_footer_bar.dart';
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
  final _supplierController = TextEditingController();

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
    _supplierController.dispose();
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
        _amountController.text = trimZeros(payment.amountPaid);
        _discountController.text = trimZeros(payment.discountAmount);
        _paymentMode = payment.paymentMode;
        _referenceController.text = payment.referenceNumber ?? '';
        _remarksController.text = payment.remarks ?? '';
      }

      setState(() {
        _suppliers = suppliers;
        _supplierController.text = _findSupplier(_selectedSupplierId)?.supplierName ?? '';
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  SupplierOption? _findSupplier(int? supplierId) {
    for (final supplier in _suppliers) {
      if (supplier.supplierId == supplierId) return supplier;
    }
    return null;
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
      bottomNavigationBar: _loading ? null : SaveFooterBar(saving: _saving, onPressed: _save),
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
          DatePickerField(date: _date, onChanged: (picked) => setState(() => _date = picked)),
          const SizedBox(height: 16),
          Autocomplete<SupplierOption>(
            textEditingController: _supplierController,
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

}
