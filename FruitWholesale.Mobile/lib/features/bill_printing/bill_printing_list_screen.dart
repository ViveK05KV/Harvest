import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/widgets/date_range_filter_row.dart';
import '../../core/widgets/paginated_list_view.dart';
import '../shop_master/shop_master_models.dart';
import '../shop_master/shop_master_service.dart';
import '../supply/supply_models.dart';
import '../supply/supply_service.dart';
import 'bill_print_screen.dart';

class _ShopFilterOption {
  final int? id;
  final String label;
  const _ShopFilterOption(this.id, this.label);
}

/// Lists recent invoices with shop + date filters; tapping one opens the
/// printable bill. Mirrors the web app's Bill Printing list.
class BillPrintingListScreen extends StatefulWidget {
  const BillPrintingListScreen({super.key});

  @override
  State<BillPrintingListScreen> createState() => _BillPrintingListScreenState();
}

class _BillPrintingListScreenState extends State<BillPrintingListScreen> {
  late final SupplyService _service = SupplyService(context.read<ApiClient>());
  late final ShopMasterService _shopService = ShopMasterService(context.read<ApiClient>());
  static final _isoFormat = DateFormat('yyyy-MM-dd');

  Key _listKey = UniqueKey();
  List<ShopMaster> _shops = [];
  int? _shopId;
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    _shopService.getAllActive().then((shops) {
      if (mounted) setState(() => _shops = shops);
    }).catchError((Object _) {});
  }

  Future<void> _openBill(SupplyListItem item) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BillPrintScreen(supplyId: item.supplyId)),
    );
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
            child: Autocomplete<_ShopFilterOption>(
              displayStringForOption: (opt) => opt.label,
              optionsBuilder: (value) {
                final query = value.text.trim().toLowerCase();
                final all = [
                  const _ShopFilterOption(null, 'All Shops'),
                  ..._shops.map((s) => _ShopFilterOption(s.shopId, s.shopName)),
                ];
                if (query.isEmpty) return all;
                return all.where((o) => o.label.toLowerCase().contains(query));
              },
              onSelected: (opt) => setState(() {
                _shopId = opt.id;
                _listKey = UniqueKey();
              }),
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) => TextFormField(
                controller: controller,
                focusNode: focusNode,
                decoration: const InputDecoration(labelText: 'Filter by Shop', isDense: true),
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
            child: PaginatedListView<SupplyListItem>(
              key: _listKey,
              fetchPage: (page) => _service.getPaged(
                pageNumber: page,
                shopId: _shopId,
                fromDate: _fromDate != null ? _isoFormat.format(_fromDate!) : null,
                toDate: _toDate != null ? _isoFormat.format(_toDate!) : null,
              ),
              emptyState: const Column(
                children: [
                  SizedBox(height: 80),
                  Icon(Icons.receipt_long_outlined, size: 48),
                  SizedBox(height: 12),
                  Center(child: Text('No invoices found')),
                ],
              ),
              itemBuilder: (context, item) => ListTile(
                leading: const CircleAvatar(child: Icon(Icons.receipt_long_outlined)),
                title: Text(item.shopName),
                subtitle: Text('${item.invoiceNo} · ${dateFormat.format(item.supplyDate)}'),
                trailing: Text(
                  currencyFormat.format(item.totalAmount),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () => _openBill(item),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
