import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/api/lookup_service.dart';
import '../../core/models/employee_option.dart';
import '../../core/widgets/date_range_filter_row.dart';
import '../../core/widgets/paginated_list_view.dart';
import 'employee_work_log_form_screen.dart';
import 'employee_work_log_models.dart';
import 'employee_work_log_service.dart';

class _EmployeeFilterOption {
  final int? id;
  final String label;
  const _EmployeeFilterOption(this.id, this.label);
}

class EmployeeWorkLogListScreen extends StatefulWidget {
  const EmployeeWorkLogListScreen({super.key});

  @override
  State<EmployeeWorkLogListScreen> createState() => _EmployeeWorkLogListScreenState();
}

class _EmployeeWorkLogListScreenState extends State<EmployeeWorkLogListScreen> {
  late final EmployeeWorkLogService _service = EmployeeWorkLogService(context.read<ApiClient>());
  late final LookupService _lookupService = LookupService(context.read<ApiClient>());
  static final _isoFormat = DateFormat('yyyy-MM-dd');
  Key _listKey = UniqueKey();
  DateTime? _fromDate;
  DateTime? _toDate;

  List<EmployeeOption> _employees = [];
  int? _employeeId;

  @override
  void initState() {
    super.initState();
    _lookupService.getActiveEmployees().then((employees) {
      if (mounted) setState(() => _employees = employees);
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

  Future<void> _openNewLog() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const EmployeeWorkLogFormScreen()),
    );
    if (created == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd-MMM-yyyy');
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Scaffold(
      appBar: AppBar(title: const Text('Salary Management')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Autocomplete<_EmployeeFilterOption>(
              displayStringForOption: (opt) => opt.label,
              optionsBuilder: (value) {
                final query = value.text.trim().toLowerCase();
                final all = [
                  const _EmployeeFilterOption(null, 'All Employees'),
                  ..._employees.map((e) => _EmployeeFilterOption(e.employeeId, e.fullName)),
                ];
                if (query.isEmpty) return all;
                return all.where((o) => o.label.toLowerCase().contains(query));
              },
              onSelected: (opt) => setState(() {
                _employeeId = opt.id;
                _listKey = UniqueKey();
              }),
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) => TextFormField(
                controller: controller,
                focusNode: focusNode,
                decoration: const InputDecoration(labelText: 'Filter by Employee', isDense: true),
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
            child: PaginatedListView<EmployeeWorkLog>(
              key: _listKey,
              fetchPage: (page) => _service.getPaged(
                pageNumber: page,
                employeeId: _employeeId,
                fromDate: _fromDate != null ? _isoFormat.format(_fromDate!) : null,
                toDate: _toDate != null ? _isoFormat.format(_toDate!) : null,
              ),
              padding: const EdgeInsets.only(bottom: 88),
              emptyState: const Column(
                children: [
                  SizedBox(height: 80),
                  Icon(Icons.work_history_outlined, size: 48),
                  SizedBox(height: 12),
                  Center(child: Text('No work log entries yet')),
                ],
              ),
              itemBuilder: (context, item) => ListTile(
                leading: const CircleAvatar(child: Icon(Icons.work_history_outlined)),
                title: Text(item.employeeName ?? ''),
                subtitle: Text(
                  '${dateFormat.format(item.workDate)} · ${item.jobType}${item.routeName != null ? ' · ${item.routeName}' : ''}',
                ),
                trailing: Text(currencyFormat.format(item.amount), style: const TextStyle(fontWeight: FontWeight.w600)),
                onTap: () async {
                  final updated = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(builder: (_) => EmployeeWorkLogFormScreen(logId: item.employeeWorkLogId)),
                  );
                  if (updated == true) _reload();
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNewLog,
        icon: const Icon(Icons.add),
        label: const Text('New Entry'),
      ),
    );
  }
}
