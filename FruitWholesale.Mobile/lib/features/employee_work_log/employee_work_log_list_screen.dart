import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/widgets/paginated_list_view.dart';
import 'employee_work_log_form_screen.dart';
import 'employee_work_log_models.dart';
import 'employee_work_log_service.dart';

class EmployeeWorkLogListScreen extends StatefulWidget {
  const EmployeeWorkLogListScreen({super.key});

  @override
  State<EmployeeWorkLogListScreen> createState() => _EmployeeWorkLogListScreenState();
}

class _EmployeeWorkLogListScreenState extends State<EmployeeWorkLogListScreen> {
  late final EmployeeWorkLogService _service = EmployeeWorkLogService(context.read<ApiClient>());
  Key _listKey = UniqueKey();

  void _reload() => setState(() => _listKey = UniqueKey());

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
      appBar: AppBar(title: const Text('Employee Salary')),
      body: PaginatedListView<EmployeeWorkLog>(
        key: _listKey,
        fetchPage: (page) => _service.getPaged(pageNumber: page),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNewLog,
        icon: const Icon(Icons.add),
        label: const Text('New Entry'),
      ),
    );
  }
}
