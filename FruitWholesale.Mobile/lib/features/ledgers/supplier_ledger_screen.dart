import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/lookup_service.dart';
import '../../core/models/supplier_option.dart';
import '../../core/widgets/paginated_list_view.dart';
import 'ledger_models.dart';
import 'ledger_service.dart';

class SupplierLedgerScreen extends StatefulWidget {
  const SupplierLedgerScreen({super.key});

  @override
  State<SupplierLedgerScreen> createState() => _SupplierLedgerScreenState();
}

class _SupplierLedgerScreenState extends State<SupplierLedgerScreen> {
  late final LedgerService _ledgerService = LedgerService(context.read<ApiClient>());
  late final LookupService _lookupService = LookupService(context.read<ApiClient>());

  List<SupplierOption> _suppliers = [];
  int? _selectedSupplierId;
  String? _error;
  bool _loadingSuppliers = true;

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  Future<void> _loadSuppliers() async {
    try {
      final suppliers = await _lookupService.getActiveSuppliers();
      setState(() {
        _suppliers = suppliers;
        _loadingSuppliers = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _loadingSuppliers = false;
      });
    }
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
            padding: const EdgeInsets.all(16),
            child: _loadingSuppliers
                ? const LinearProgressIndicator()
                : DropdownButtonFormField<int>(
                    initialValue: _selectedSupplierId,
                    decoration: const InputDecoration(labelText: 'Select Supplier'),
                    items: [
                      for (final supplier in _suppliers)
                        DropdownMenuItem(value: supplier.supplierId, child: Text(supplier.supplierName)),
                    ],
                    onChanged: (value) => setState(() => _selectedSupplierId = value),
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
