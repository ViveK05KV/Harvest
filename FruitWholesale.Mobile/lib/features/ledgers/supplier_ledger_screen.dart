import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/widgets/net_balance_badge.dart';
import '../../core/widgets/paginated_list_view.dart';
import '../supplier_master/supplier_master_models.dart';
import '../supplier_master/supplier_master_service.dart';
import 'ledger_models.dart';
import 'ledger_service.dart';

class _FilterOption {
  final int? id;
  final String label;
  const _FilterOption(this.id, this.label);
}

class SupplierLedgerScreen extends StatefulWidget {
  const SupplierLedgerScreen({super.key});

  @override
  State<SupplierLedgerScreen> createState() => _SupplierLedgerScreenState();
}

class _SupplierLedgerScreenState extends State<SupplierLedgerScreen> {
  late final LedgerService _ledgerService = LedgerService(context.read<ApiClient>());
  late final SupplierMasterService _supplierService = SupplierMasterService(context.read<ApiClient>());

  final _supplierController = TextEditingController();

  List<SupplierMaster> _suppliers = [];
  int? _selectedSupplierId;
  String? _error;
  bool _loadingSuppliers = true;

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  @override
  void dispose() {
    _supplierController.dispose();
    super.dispose();
  }

  Future<void> _loadSuppliers() async {
    try {
      final suppliers = await _supplierService.getAllActive();
      setState(() {
        _suppliers = suppliers;
        _loadingSuppliers = false;
        _supplierController.text = _selectedSupplier?.supplierName ?? '';
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _loadingSuppliers = false;
      });
    }
  }

  SupplierMaster? get _selectedSupplier {
    if (_selectedSupplierId == null) return null;
    for (final supplier in _suppliers) {
      if (supplier.supplierId == _selectedSupplierId) return supplier;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd-MMM-yyyy');
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Scaffold(
      appBar: AppBar(title: const Text('Supplier Ledger')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _loadingSuppliers
                ? const LinearProgressIndicator()
                : Autocomplete<_FilterOption>(
                    textEditingController: _supplierController,
                    displayStringForOption: (opt) => opt.label,
                    optionsBuilder: (value) {
                      final query = value.text.trim().toLowerCase();
                      final all = [
                        const _FilterOption(null, 'All Suppliers'),
                        ..._suppliers.map((s) => _FilterOption(s.supplierId, s.supplierName)),
                      ];
                      if (query.isEmpty) return all;
                      return all.where((o) => o.label.toLowerCase().contains(query));
                    },
                    onSelected: (opt) => setState(() {
                      _selectedSupplierId = opt.id;
                      _supplierController.text = opt.label;
                    }),
                    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) => TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: const InputDecoration(labelText: 'Select Supplier'),
                    ),
                  ),
          ),
          if (_selectedSupplier != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: NetBalanceBadge(
                netBalance: _selectedSupplier!.netBalance,
                tooltip: _selectedSupplier!.linkedShopId != null
                    ? 'Combined position with linked Shop: ${_selectedSupplier!.linkedShopName}'
                    : "${_selectedSupplier!.supplierName}'s outstanding balance",
              ),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          if (_selectedSupplierId == null)
            const Expanded(child: Center(child: Text('Select a supplier to view its ledger')))
          else
            Expanded(
              child: PaginatedListView<LedgerEntry>(
                key: ValueKey(_selectedSupplierId),
                fetchPage: (page) => _ledgerService.getSupplierLedger(_selectedSupplierId!, pageNumber: page),
                emptyState: const Column(
                  children: [SizedBox(height: 80), Center(child: Text('No transactions yet'))],
                ),
                itemBuilder: (context, entry) {
                  final isCredit = entry.credit > 0;
                  return ListTile(
                    title: Text(entry.transactionType),
                    subtitle: Text(
                      '${dateFormat.format(entry.transactionDate)}${entry.narration != null ? ' · ${entry.narration}' : ''}',
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          isCredit ? '-${currencyFormat.format(entry.credit)}' : '+${currencyFormat.format(entry.debit)}',
                          style: TextStyle(fontWeight: FontWeight.w600, color: isCredit ? Colors.green : Colors.red),
                        ),
                        Text('Bal: ${currencyFormat.format(entry.runningBalance)}', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
