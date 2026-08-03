import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/lookup_service.dart';
import '../../core/models/shop_option.dart';
import '../../core/utils/number_format_utils.dart';
import '../../core/widgets/date_picker_field.dart';
import '../../core/widgets/error_banner.dart';
import '../../core/widgets/save_footer_bar.dart';
import 'collection_models.dart';
import 'collection_service.dart';

class CollectionFormScreen extends StatefulWidget {
  final int? collectionId;

  const CollectionFormScreen({super.key, this.collectionId});

  bool get isEditing => collectionId != null;

  @override
  State<CollectionFormScreen> createState() => _CollectionFormScreenState();
}

class _CollectionFormScreenState extends State<CollectionFormScreen> {
  late final CollectionService _collectionService = CollectionService(context.read<ApiClient>());
  late final LookupService _lookupService = LookupService(context.read<ApiClient>());

  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _discountController = TextEditingController(text: '0');
  final _referenceController = TextEditingController();
  final _remarksController = TextEditingController();

  List<ShopOption> _shops = [];
  int? _selectedShopId;
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
      final shops = await _lookupService.getActiveShops();

      if (widget.isEditing) {
        final collection = await _collectionService.getById(widget.collectionId!);
        _selectedShopId = collection.shopId;
        _date = collection.collectionDate;
        _amountController.text = trimZeros(collection.amountReceived);
        _discountController.text = trimZeros(collection.discountAmount);
        _paymentMode = collection.paymentMode;
        _referenceController.text = collection.referenceNumber ?? '';
        _remarksController.text = collection.remarks ?? '';
      }

      setState(() => _shops = shops);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  ShopOption? _findShop(int? shopId) {
    for (final shop in _shops) {
      if (shop.shopId == shopId) return shop;
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedShopId == null) {
      setState(() => _error = 'Select a shop.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final collection = Collection(
      collectionDate: _date,
      shopId: _selectedShopId!,
      amountReceived: double.tryParse(_amountController.text) ?? 0,
      discountAmount: double.tryParse(_discountController.text) ?? 0,
      paymentMode: _paymentMode,
      referenceNumber: _referenceController.text.trim().isEmpty ? null : _referenceController.text.trim(),
      remarks: _remarksController.text.trim().isEmpty ? null : _remarksController.text.trim(),
    );

    try {
      if (widget.isEditing) {
        await _collectionService.update(widget.collectionId!, collection);
      } else {
        await _collectionService.create(collection);
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
      appBar: AppBar(title: Text(widget.isEditing ? 'Edit Collection' : 'New Collection')),
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
          Autocomplete<ShopOption>(
            initialValue: TextEditingValue(text: _findShop(_selectedShopId)?.shopName ?? ''),
            displayStringForOption: (shop) => shop.shopName,
            optionsBuilder: (value) {
              final query = value.text.trim().toLowerCase();
              if (query.isEmpty) return _shops;
              return _shops.where((shop) => shop.shopName.toLowerCase().contains(query));
            },
            onSelected: (shop) => setState(() => _selectedShopId = shop.shopId),
            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
              return TextFormField(
                controller: controller,
                focusNode: focusNode,
                decoration: const InputDecoration(labelText: 'Shop'),
              );
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _amountController,
            decoration: const InputDecoration(labelText: 'Amount Received'),
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
              labelText: 'Discount Given',
              helperText: 'Optional — reduces the shop\'s outstanding in addition to the amount received',
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
