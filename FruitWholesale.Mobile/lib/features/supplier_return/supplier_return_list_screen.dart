import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/widgets/date_range_filter_row.dart';
import '../../core/widgets/paginated_list_view.dart';
import '../supplier_master/supplier_master_models.dart';
import '../supplier_master/supplier_master_service.dart';
import 'supplier_return_form_screen.dart';
import 'supplier_return_models.dart';
import 'supplier_return_service.dart';

class _SupplierFilterOption {
  final int? id;
  final String label;
  const _SupplierFilterOption(this.id, this.label);
}

class SupplierReturnListScreen extends StatefulWidget {
  const SupplierReturnListScreen({super.key});

  @override
  State<SupplierReturnListScreen> createState() => _SupplierReturnListScreenState();
}

class _SupplierReturnListScreenState extends State<SupplierReturnListScreen> {
  late final SupplierReturnService _service = SupplierReturnService(context.read<ApiClient>());
  late final SupplierMasterService _supplierService = SupplierMasterService(context.read<ApiClient>());
  static final _isoFormat = DateFormat('yyyy-MM-dd');
  Key _listKey = UniqueKey();

  List<SupplierMaster> _suppliers = [];
  int? _supplierId;
  DateTime? _fromDate;
  DateTime? _toDate;
  String _searchTerm = '';
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _supplierService.getAllActive().then((suppliers) {
      if (mounted) setState(() => _suppliers = suppliers);
    }).catchError((Object _) {});
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      setState(() {
        _searchTerm = value;
        _listKey = UniqueKey();
      });
    });
  }

  void _reload() => setState(() => _listKey = UniqueKey());

  Future<void> _openNew() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const SupplierReturnFormScreen()),
    );
    if (created == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd-MMM-yyyy');
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: TextField(
              onChanged: _onSearchChanged,
              decoration: const InputDecoration(labelText: 'Search', hintText: 'Reference no / supplier', prefixIcon: Icon(Icons.search)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
            onFromChanged: (date) => setState(() {
              _fromDate = date;
              _listKey = UniqueKey();
            }),
            onToChanged: (date) => setState(() {
              _toDate = date;
              _listKey = UniqueKey();
            }),
          ),
          Expanded(
            child: PaginatedListView<SupplierReturnListItem>(
              key: _listKey,
              fetchPage: (page) => _service.getPaged(
                pageNumber: page,
                searchTerm: _searchTerm,
                supplierId: _supplierId,
                fromDate: _fromDate != null ? _isoFormat.format(_fromDate!) : null,
                toDate: _toDate != null ? _isoFormat.format(_toDate!) : null,
              ),
              padding: const EdgeInsets.only(bottom: 88),
              emptyState: const Column(
                children: [
                  SizedBox(height: 80),
                  Icon(Icons.keyboard_return_outlined, size: 48),
                  SizedBox(height: 12),
                  Center(child: Text('No supplier returns yet')),
                ],
              ),
              itemBuilder: (context, item) => ListTile(
                leading: const CircleAvatar(child: Icon(Icons.keyboard_return_outlined)),
                title: Text(item.supplierName),
                subtitle: Text('${item.referenceNo} · ${dateFormat.format(item.returnDate)}'),
                trailing: Text(
                  currencyFormat.format(item.totalAmount),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () async {
                  final updated = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(builder: (_) => SupplierReturnFormScreen(supplierReturnId: item.supplierReturnId)),
                  );
                  if (updated == true) _reload();
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNew,
        icon: const Icon(Icons.add),
        label: const Text('New Return'),
      ),
    );
  }
}
