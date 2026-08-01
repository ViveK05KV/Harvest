import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/lookup_service.dart';
import '../../core/models/route_option.dart';
import '../../core/models/supplier_option.dart';
import '../../core/widgets/error_banner.dart';
import '../../core/widgets/save_button.dart';
import 'shop_master_models.dart';
import 'shop_master_service.dart';

class ShopMasterFormScreen extends StatefulWidget {
  final int? shopId;

  const ShopMasterFormScreen({super.key, this.shopId});

  bool get isEditing => shopId != null;

  @override
  State<ShopMasterFormScreen> createState() => _ShopMasterFormScreenState();
}

class _ShopMasterFormScreenState extends State<ShopMasterFormScreen> {
  late final ShopMasterService _service = ShopMasterService(context.read<ApiClient>());
  late final LookupService _lookupService = LookupService(context.read<ApiClient>());

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ownerController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _openingBalanceController = TextEditingController(text: '0');
  final _creditLimitController = TextEditingController(text: '0');

  List<RouteOption> _routes = [];
  int? _routeId;

  List<SupplierOption> _suppliers = [];
  int? _linkedSupplierId;

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
    _nameController.dispose();
    _ownerController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _openingBalanceController.dispose();
    _creditLimitController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final routes = await _lookupService.getActiveRoutes();
      final suppliers = await _lookupService.getActiveSuppliers();
      if (widget.isEditing) {
        final shop = await _service.getById(widget.shopId!);
        _nameController.text = shop.shopName;
        _ownerController.text = shop.ownerName ?? '';
        _phoneController.text = shop.phone ?? '';
        _addressController.text = shop.address ?? '';
        _openingBalanceController.text = shop.openingBalance.toStringAsFixed(2);
        _creditLimitController.text = shop.creditLimit.toStringAsFixed(2);
        _routeId = shop.routeId;
        _linkedSupplierId = shop.linkedSupplierId;
      }
      setState(() {
        _routes = routes;
        _suppliers = suppliers;
      });
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

    final shop = ShopMaster(
      shopName: _nameController.text.trim(),
      ownerName: _ownerController.text.trim().isEmpty ? null : _ownerController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      openingBalance: double.tryParse(_openingBalanceController.text) ?? 0,
      creditLimit: double.tryParse(_creditLimitController.text) ?? 0,
      routeId: _routeId,
      linkedSupplierId: _linkedSupplierId,
    );

    try {
      if (widget.isEditing) {
        await _service.update(widget.shopId!, shop);
      } else {
        await _service.create(shop);
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
      appBar: AppBar(title: Text(widget.isEditing ? 'Edit Shop' : 'New Shop')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_error != null) ...[
                    ErrorBanner(_error!),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Shop Name'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Shop name is required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _ownerController,
                    decoration: const InputDecoration(labelText: 'Owner Name'),
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
                  DropdownButtonFormField<int?>(
                    initialValue: _routeId,
                    decoration: const InputDecoration(labelText: 'Route'),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('None')),
                      for (final route in _routes) DropdownMenuItem(value: route.routeId, child: Text(route.routeName)),
                    ],
                    onChanged: (value) => setState(() => _routeId = value),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int?>(
                    initialValue: _linkedSupplierId,
                    decoration: const InputDecoration(
                      labelText: 'Linked Supplier',
                      helperText: 'If this shop is also one of your suppliers, link it to see a combined net balance.',
                      helperMaxLines: 2,
                    ),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('Not linked')),
                      for (final supplier in _suppliers)
                        DropdownMenuItem(value: supplier.supplierId, child: Text(supplier.supplierName)),
                    ],
                    onChanged: (value) => setState(() => _linkedSupplierId = value),
                  ),
                  const SizedBox(height: 16),
                  if (!widget.isEditing) ...[
                    TextFormField(
                      controller: _openingBalanceController,
                      decoration: const InputDecoration(labelText: 'Opening Balance'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _creditLimitController,
                    decoration: const InputDecoration(labelText: 'Credit Limit'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 24),
                  SaveButton(saving: _saving, onPressed: _save),
                ],
              ),
            ),
    );
  }
}
