import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/lookup_service.dart';
import '../../core/models/employee_option.dart';
import 'report_service.dart';

enum _ReportType {
  dailySales('Sales', needsDateRange: true),
  dailyCollection('Collection', needsDateRange: true),
  dailyExpense('Expense', needsDateRange: true),
  purchase('Purchase Report', needsDateRange: true),
  fruitSales('Fruit Sales', needsDateRange: true),
  outstanding('Outstanding', needsDateRange: false),
  profitSummary('Profit Summary', needsDateRange: true),
  expenseByCategory('Expense by Category', needsDateRange: true),
  salaryByEmployee('Salary by Employee', needsDateRange: true);

  final String label;
  final bool needsDateRange;

  const _ReportType(this.label, {required this.needsDateRange});
}

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late final ReportService _service = ReportService(context.read<ApiClient>());
  late final LookupService _lookupService = LookupService(context.read<ApiClient>());

  _ReportType _type = _ReportType.dailySales;
  DateTime _from = DateTime.now().subtract(const Duration(days: 30));
  DateTime _to = DateTime.now();

  List<EmployeeOption> _employees = [];
  int? _selectedEmployeeId;
  final _employeeController = TextEditingController();

  List<Widget>? _rows;
  String? _error;
  bool _loading = false;
  int _loadRequestId = 0;

  @override
  void initState() {
    super.initState();
    _lookupService.getActiveEmployees().then((employees) {
      if (mounted) setState(() => _employees = employees);
    });
    _run();
  }

  @override
  void dispose() {
    _employeeController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _from : _to,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked == null) return;
    setState(() => isFrom ? _from = picked : _to = picked);
  }

  Future<void> _run() async {
    // A stale response from a previous tab/filter must not overwrite a newer
    // one's data or flip loading false while a newer request is still pending.
    final requestId = ++_loadRequestId;
    setState(() {
      _loading = true;
      _error = null;
    });

    final dateFormat = DateFormat('dd-MMM-yyyy');
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    try {
      List<Widget> rows;
      switch (_type) {
        case _ReportType.dailySales:
          final data = await _service.dailySales(_from, _to);
          rows = [
            for (final r in data)
              ListTile(
                title: Text(r.shopName),
                subtitle: Text('${r.invoiceNo} · ${dateFormat.format(r.supplyDate)}'),
                trailing: Text(currencyFormat.format(r.totalAmount)),
              ),
          ];
        case _ReportType.dailyCollection:
          final data = await _service.dailyCollection(_from, _to);
          rows = [
            for (final r in data)
              ListTile(
                title: Text(r.shopName),
                subtitle: Text('${r.paymentMode} · ${dateFormat.format(r.collectionDate)}'),
                trailing: Text(currencyFormat.format(r.amountReceived)),
              ),
          ];
        case _ReportType.dailyExpense:
          final data = await _service.dailyExpense(_from, _to);
          rows = [
            for (final r in data)
              ListTile(
                title: Text(r.categoryName),
                subtitle: Text('${r.paidTo} · ${r.paymentMode} · ${dateFormat.format(r.expenseDate)}'),
                trailing: Text(currencyFormat.format(r.amount)),
              ),
          ];
        case _ReportType.purchase:
          final data = await _service.purchase(_from, _to);
          rows = [
            for (final r in data)
              ListTile(
                title: Text(r.supplierName),
                subtitle: Text('${r.invoiceNo} · ${dateFormat.format(r.purchaseDate)}'),
                trailing: Text(currencyFormat.format(r.totalAmount)),
              ),
          ];
        case _ReportType.fruitSales:
          final data = await _service.fruitSales(_from, _to);
          rows = [
            for (final r in data)
              ListTile(
                title: Text(r.fruitName),
                subtitle: Text('${r.totalQuantity} ${r.unit}'),
                trailing: Text(currencyFormat.format(r.totalAmount)),
              ),
          ];
        case _ReportType.outstanding:
          final data = await _service.outstanding();
          rows = [
            for (final r in data)
              ListTile(
                title: Text(r.name),
                subtitle: Text(r.type),
                trailing: Text(currencyFormat.format(r.outstandingAmount)),
              ),
          ];
        case _ReportType.profitSummary:
          final data = await _service.profitSummary(_from, _to);
          rows = [
            for (final r in data)
              ListTile(
                title: Text(r.month),
                subtitle: Text(
                  'Sales ${currencyFormat.format(r.totalSales)} · Purchases ${currencyFormat.format(r.totalPurchases)} · Expenses ${currencyFormat.format(r.totalExpenses)}',
                ),
                trailing: Text(
                  currencyFormat.format(r.netProfit),
                  style: TextStyle(fontWeight: FontWeight.w600, color: r.netProfit >= 0 ? Colors.green : Colors.red),
                ),
              ),
          ];
        case _ReportType.expenseByCategory:
          final data = await _service.expenseByCategory(_from, _to);
          rows = [
            for (final r in data)
              ListTile(
                title: Text(r.categoryName),
                trailing: Text(currencyFormat.format(r.totalAmount), style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
          ];
        case _ReportType.salaryByEmployee:
          final data = await _service.salaryByEmployee(_from, _to, employeeId: _selectedEmployeeId);
          rows = [
            for (final r in data)
              ListTile(
                title: Text(r.employeeName),
                subtitle: Text('${r.workDaysCount} work day${r.workDaysCount == 1 ? '' : 's'}'),
                trailing: Text(currencyFormat.format(r.totalAmount), style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
          ];
      }
      if (!mounted || requestId != _loadRequestId) return;
      setState(() => _rows = rows);
    } on ApiException catch (e) {
      if (!mounted || requestId != _loadRequestId) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted && requestId == _loadRequestId) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd-MMM-yyyy');
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                DropdownButtonFormField<_ReportType>(
                  initialValue: _type,
                  decoration: const InputDecoration(labelText: 'Report'),
                  items: [for (final t in _ReportType.values) DropdownMenuItem(value: t, child: Text(t.label))],
                  onChanged: (value) {
                    setState(() => _type = value!);
                    _run();
                  },
                ),
                if (_type.needsDateRange) ...[
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
                      IconButton(icon: const Icon(Icons.search), onPressed: _run),
                    ],
                  ),
                ],
                if (_type == _ReportType.salaryByEmployee) ...[
                  const SizedBox(height: 12),
                  Autocomplete<EmployeeOption>(
                    textEditingController: _employeeController,
                    displayStringForOption: (employee) => employee.fullName,
                    optionsBuilder: (value) {
                      final query = value.text.trim().toLowerCase();
                      if (query.isEmpty) return _employees;
                      return _employees.where((e) => e.fullName.toLowerCase().contains(query));
                    },
                    onSelected: (employee) {
                      setState(() => _selectedEmployeeId = employee.employeeId);
                      _run();
                    },
                    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                      return TextFormField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          labelText: 'Filter by Employee (optional)',
                          suffixIcon: _selectedEmployeeId == null
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    controller.clear();
                                    setState(() => _selectedEmployeeId = null);
                                    _run();
                                  },
                                ),
                        ),
                      );
                    },
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
              child: _rows!.isEmpty
                  ? const Center(child: Text('No data for the selected range'))
                  : ListView.separated(
                      itemCount: _rows!.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) => _rows![index],
                    ),
            ),
        ],
      ),
    );
  }
}
