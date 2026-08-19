import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/widgets/date_range_filter_row.dart';
import '../../core/widgets/paginated_list_view.dart';
import '../supplier_master/supplier_master_models.dart';
import '../supplier_master/supplier_master_service.dart';
import 'supplier_payment_form_screen.dart';
import 'supplier_payment_models.dart';
import 'supplier_payment_service.dart';

class _SupplierFilterOption {
  final int? id;
  final String label;
  const _SupplierFilterOption(this.id, this.label);
}

class SupplierPaymentListScreen extends StatefulWidget {
  const SupplierPaymentListScreen({super.key});

  @override
  State<SupplierPaymentListScreen> createState() => _SupplierPaymentListScreenState();
}

class _SupplierPaymentListScreenState extends State<SupplierPaymentListScreen> {
  late final SupplierPaymentService _service = SupplierPaymentService(context.read<ApiClient>());
  late final SupplierMasterService _supplierService = SupplierMasterService(context.read<ApiClient>());
  static final _isoFormat = DateFormat('yyyy-MM-dd');
  Key _listKey = UniqueKey();
  DateTime? _fromDate;
  DateTime? _toDate;

  List<SupplierMaster> _suppliers = [];
  int? _supplierId;

  @override
  void initState() {
    super.initState();
    _supplierService.getAllActive().then((suppliers) {
      if (mounted) setState(() => _suppliers = suppliers);
    }).catchError((Object _) {});
  }

  void _reload() => setState(() => _listKey = UniqueKey());

  void _onFromChanged(DateTime? date) => setState(() {
        _fromDate = date;
        _listKey = UniqueKey();
      });

  void _onToChanged(DateTime? date) => setState(() {
        _toDate = date;
        _listKey = UniqueKey();
      });

  Future<void> _openNewPayment() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const SupplierPaymentFormScreen()),
    );
    if (created == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd-MMM-yyyy');
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Scaffold(
      appBar: AppBar(title: const Text('Supplier Payments')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Autocomplete<_SupplierFilterOption>(
              displayStringForOption: (opt) => opt.label,
              optionsBuilder: (value) {
                final query = value.text.trim().toLowerCase();
                final all = [
                  const _SupplierFilterOption(null, 'All Suppliers'),
                  ..._suppliers.map((s) => _SupplierFilterOption(s.supplierId, s.supplierName)),
                ];
                if (query.isEmpty) return all;
                return all.where((o) => o.label.toLowerCase().contains(query));
              },
              onSelected: (opt) => setState(() {
                _supplierId = opt.id;
                _listKey = UniqueKey();
              }),
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) => TextFormField(
                controller: controller,
                focusNode: focusNode,
                decoration: const InputDecoration(labelText: 'Filter by Supplier', isDense: true),
              ),
            ),
          ),
          DateRangeFilterRow(
            fromDate: _fromDate,
            toDate: _toDate,
            onFromChanged: _onFromChanged,
            onToChanged: _onToChanged,
          ),
          Expanded(
            child: PaginatedListView<SupplierPayment>(
              key: _listKey,
              fetchPage: (page) => _service.getPaged(
                pageNumber: page,
                supplierId: _supplierId,
                fromDate: _fromDate != null ? _isoFormat.format(_fromDate!) : null,
                toDate: _toDate != null ? _isoFormat.format(_toDate!) : null,
              ),
              padding: const EdgeInsets.only(bottom: 88),
              emptyState: const Column(
                children: [
                  SizedBox(height: 80),
                  Icon(Icons.account_balance_wallet_outlined, size: 48),
                  SizedBox(height: 12),
                  Center(child: Text('No supplier payments yet')),
                ],
              ),
              itemBuilder: (context, item) => ListTile(
                leading: const CircleAvatar(child: Icon(Icons.account_balance_wallet_outlined)),
                title: Text(item.supplierName ?? ''),
                subtitle: Text(
                  '${dateFormat.format(item.paymentDate)} · ${item.paymentMode}'
                  '${item.discountAmount > 0 ? ' · Discount ${currencyFormat.format(item.discountAmount)}' : ''}',
                ),
                trailing: Text(currencyFormat.format(item.amountPaid), style: const TextStyle(fontWeight: FontWeight.w600)),
                onTap: () async {
                  final updated = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(builder: (_) => SupplierPaymentFormScreen(paymentId: item.supplierPaymentId)),
                  );
                  if (updated == true) _reload();
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNewPayment,
        icon: const Icon(Icons.add),
        label: const Text('New Payment'),
      ),
    );
  }
}
