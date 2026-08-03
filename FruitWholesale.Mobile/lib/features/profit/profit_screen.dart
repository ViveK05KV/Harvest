import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/lookup_service.dart';
import '../../core/models/shop_option.dart';
import 'profit_service.dart';

enum _ProfitView {
  businessTotal('Business Total'),
  byShop('By Shop'),
  byFruit('By Fruit'),
  byShopFruit('By Shop & Fruit');

  final String label;

  const _ProfitView(this.label);
}

class _FilterOption {
  final int? id;
  final String label;
  const _FilterOption(this.id, this.label);
}

// No purchase/sale history exists before this date - only opening shop/supplier
// balances were carried forward, so profit reporting is scoped to this date
// onward everywhere (matches ProfitConstants.TrackingStartDate on the backend).
final DateTime _profitTrackingStartDate = DateTime(2026, 8, 1);

class ProfitScreen extends StatefulWidget {
  const ProfitScreen({super.key});

  @override
  State<ProfitScreen> createState() => _ProfitScreenState();
}

class _ProfitScreenState extends State<ProfitScreen> {
  late final ProfitService _service = ProfitService(context.read<ApiClient>());
  late final LookupService _lookup = LookupService(context.read<ApiClient>());

  _ProfitView _view = _ProfitView.businessTotal;
  DateTime _from = DateTime(2026, 8, 1);
  DateTime _to = DateTime.now();
  bool _tillToday = false;
  int? _selectedShopId;

  List<ShopOption> _shops = [];
  List<Widget>? _rows;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _lookup.getActiveShops().then((shops) => setState(() => _shops = shops));
    _run();
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _from : _to,
      firstDate: _profitTrackingStartDate,
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked == null) return;
    setState(() => isFrom ? _from = picked : _to = picked);
    _run();
  }

  ShopOption? _findShop(int? shopId) {
    for (final shop in _shops) {
      if (shop.shopId == shopId) return shop;
    }
    return null;
  }

  bool get _usesDateFilter => _view == _ProfitView.byShop || _view == _ProfitView.byFruit || _view == _ProfitView.byShopFruit;
  bool get _usesTillToday => _view == _ProfitView.byShop || _view == _ProfitView.byFruit;
  bool get _usesShopFilter => _view == _ProfitView.byShop || _view == _ProfitView.byShopFruit;

  Future<void> _run() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final dateFormat = DateFormat('dd-MMM-yyyy');
    final useAllTime = _tillToday && _usesTillToday;
    final from = useAllTime ? _profitTrackingStartDate : _from;
    final to = useAllTime ? null : _to;

    Widget marginText(double margin) => Text(
          '${margin.toStringAsFixed(2)}%',
          style: TextStyle(color: margin < 0 ? Colors.red : Colors.green, fontWeight: FontWeight.w600),
        );

    try {
      List<Widget> rows;
      switch (_view) {
        case _ProfitView.businessTotal:
          final data = await _service.businessTotal();
          if (!mounted) return;
          rows = [
            Card(
              margin: const EdgeInsets.only(top: 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Revenue (Till Date)', style: Theme.of(context).textTheme.bodySmall),
                    Text(currencyFormat.format(data.revenue), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    Text('Total Cost of Goods', style: Theme.of(context).textTheme.bodySmall),
                    Text(currencyFormat.format(data.cost), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    Text('Total Profit (Till Date)', style: Theme.of(context).textTheme.bodySmall),
                    Text(
                      currencyFormat.format(data.profit),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: data.profit < 0 ? Colors.red : Colors.green,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Margin', style: Theme.of(context).textTheme.bodySmall),
                    marginText(data.marginPercent),
                  ],
                ),
              ),
            ),
          ];
        case _ProfitView.byShop:
          if (_selectedShopId != null) {
            final data = await _service.shopDaily(shopId: _selectedShopId, from: from, to: to);
            rows = [
              for (final r in data)
                ListTile(
                  title: Text(dateFormat.format(r.date)),
                  subtitle: Text('Revenue ${currencyFormat.format(r.revenue)} · Cost ${currencyFormat.format(r.cost)}'),
                  trailing: Text(currencyFormat.format(r.profit),
                      style: TextStyle(fontWeight: FontWeight.w600, color: r.profit < 0 ? Colors.red : Colors.green)),
                ),
            ];
          } else {
            final data = await _service.shopSummary(from: from, to: to);
            rows = [
              for (final r in data)
                ListTile(
                  title: Text(r.shopName),
                  subtitle: Text('Revenue ${currencyFormat.format(r.revenue)} · Cost ${currencyFormat.format(r.cost)}'),
                  trailing: Text(currencyFormat.format(r.profit),
                      style: TextStyle(fontWeight: FontWeight.w600, color: r.profit < 0 ? Colors.red : Colors.green)),
                ),
            ];
          }
        case _ProfitView.byFruit:
          final data = await _service.fruitSummary(from: from, to: to);
          rows = [
            for (final r in data)
              ListTile(
                title: Text('${r.fruitName} (${r.unit})'),
                subtitle: Text('Qty ${r.quantitySold.toStringAsFixed(2)} · Revenue ${currencyFormat.format(r.revenue)}'),
                trailing: Text(currencyFormat.format(r.profit),
                    style: TextStyle(fontWeight: FontWeight.w600, color: r.profit < 0 ? Colors.red : Colors.green)),
              ),
          ];
        case _ProfitView.byShopFruit:
          final data = await _service.shopFruit(shopId: _selectedShopId, from: from, to: to);
          rows = [
            for (final r in data)
              ListTile(
                title: Text('${r.fruitName} (${r.unit})'),
                subtitle: Text('${r.shopName} · Qty ${r.quantitySold.toStringAsFixed(2)}'),
                trailing: Text(currencyFormat.format(r.profit),
                    style: TextStyle(fontWeight: FontWeight.w600, color: r.profit < 0 ? Colors.red : Colors.green)),
              ),
          ];
      }
      setState(() => _rows = rows);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd-MMM-yyyy');
    return Scaffold(
      appBar: AppBar(title: const Text('Profit Calculator')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                DropdownButtonFormField<_ProfitView>(
                  initialValue: _view,
                  decoration: const InputDecoration(labelText: 'View'),
                  items: [for (final v in _ProfitView.values) DropdownMenuItem(value: v, child: Text(v.label))],
                  onChanged: (value) {
                    setState(() {
                      _view = value!;
                      _selectedShopId = null;
                    });
                    _run();
                  },
                ),
                if (_usesShopFilter) ...[
                  const SizedBox(height: 12),
                  Autocomplete<_FilterOption>(
                    initialValue: TextEditingValue(text: _findShop(_selectedShopId)?.shopName ?? ''),
                    displayStringForOption: (opt) => opt.label,
                    optionsBuilder: (value) {
                      final query = value.text.trim().toLowerCase();
                      final all = [
                        const _FilterOption(null, 'All Shops'),
                        ..._shops.map((s) => _FilterOption(s.shopId, s.shopName)),
                      ];
                      if (query.isEmpty) return all;
                      return all.where((o) => o.label.toLowerCase().contains(query));
                    },
                    onSelected: (opt) {
                      setState(() => _selectedShopId = opt.id);
                      _run();
                    },
                    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) => TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        labelText: _view == _ProfitView.byShop ? 'Shop (for daily breakdown)' : 'Shop (optional filter)',
                      ),
                    ),
                  ),
                ],
                if (_usesTillToday) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Till Today'),
                      Switch(
                        value: _tillToday,
                        onChanged: (value) {
                          setState(() => _tillToday = value);
                          _run();
                        },
                      ),
                    ],
                  ),
                ],
                if (_usesDateFilter && !(_tillToday && _usesTillToday)) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _pickDate(isFrom: true),
                          child: InputDecorator(
                            decoration: const InputDecoration(labelText: 'From'),
                            child: Text(dateFormat.format(_from)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () => _pickDate(isFrom: false),
                          child: InputDecorator(
                            decoration: const InputDecoration(labelText: 'To'),
                            child: Text(dateFormat.format(_to)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (_loading) const Expanded(child: Center(child: CircularProgressIndicator())),
          if (!_loading && _error != null)
            Expanded(child: Center(child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)))),
          if (!_loading && _error == null && _rows != null)
            Expanded(
              child: _view == _ProfitView.businessTotal
                  ? ListView(padding: const EdgeInsets.symmetric(horizontal: 16), children: _rows!)
                  : (_rows!.isEmpty
                      ? const Center(child: Text('No data for the selected range'))
                      : ListView.separated(
                          itemCount: _rows!.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) => _rows![index],
                        )),
            ),
        ],
      ),
    );
  }
}
