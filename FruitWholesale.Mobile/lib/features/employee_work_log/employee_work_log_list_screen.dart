import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/lookup_service.dart';
import '../../core/models/employee_option.dart';
import '../../core/widgets/balance_adjustment_dialog.dart';
import '../../core/widgets/date_range_filter_row.dart';
import '../../core/widgets/paginated_list_view.dart';
import '../employee_loan/employee_loan_models.dart';
import '../employee_loan/employee_loan_repayment_dialog.dart';
import '../employee_loan/employee_loan_service.dart';
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

class _EmployeeWorkLogListScreenState extends State<EmployeeWorkLogListScreen> with SingleTickerProviderStateMixin {
  late final EmployeeWorkLogService _service = EmployeeWorkLogService(context.read<ApiClient>());
  late final EmployeeLoanService _loanService = EmployeeLoanService(context.read<ApiClient>());
  late final LookupService _lookupService = LookupService(context.read<ApiClient>());
  late final TabController _tabController = TabController(length: 2, vsync: this)..addListener(_onTabChange);

  static final _isoFormat = DateFormat('yyyy-MM-dd');
  Key _listKey = UniqueKey();
  DateTime? _fromDate;
  DateTime? _toDate;

  List<EmployeeOption> _employees = [];
  int? _employeeId;

  // --- Loan Management tab ---
  List<EmployeeLoanSummaryRow> _loanSummary = [];
  Map<int, EmployeeLoanSummaryRow> _loanSummaryById = {};
  bool _loanLoading = false;
  List<EmployeeLoanHistoryRow> _loanHistory = [];
  bool _loanHistoryLoading = false;
  int? _selectedLoanEmployeeId;
  final _loanEmployeeController = TextEditingController();
  final _loanEmployeeFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _lookupService.getActiveEmployees().then((employees) {
      if (mounted) setState(() => _employees = employees);
    }).catchError((Object _) {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loanEmployeeController.dispose();
    _loanEmployeeFocusNode.dispose();
    super.dispose();
  }

  void _onTabChange() {
    if (_tabController.indexIsChanging) return;
    if (_tabController.index == 1 && _loanSummary.isEmpty) _loadLoanSummary();
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

  EmployeeLoanSummaryRow? get _selectedLoanEmployee =>
      _selectedLoanEmployeeId == null ? null : _loanSummaryById[_selectedLoanEmployeeId];

  Future<void> _loadLoanSummary() async {
    setState(() => _loanLoading = true);
    try {
      final rows = await _loanService.getSummary();
      if (!mounted) return;
      _loanSummaryById = {for (final r in rows) r.employeeId: r};
      final active = rows.where((r) => r.outstandingLoan > 0).toList();
      setState(() {
        _loanSummary = active;
        _loanLoading = false;
      });
      if (_selectedLoanEmployeeId == null && active.isNotEmpty) {
        _selectLoanEmployee(active.first.employeeId);
      }
    } on ApiException {
      if (mounted) setState(() => _loanLoading = false);
    }
  }

  void _selectLoanEmployee(int employeeId) {
    setState(() {
      _selectedLoanEmployeeId = employeeId;
      _loanEmployeeController.text = _loanSummaryById[employeeId]?.employeeName ?? '';
    });
    _loadLoanHistory();
  }

  Future<void> _loadLoanHistory() async {
    if (_selectedLoanEmployeeId == null) return;
    setState(() => _loanHistoryLoading = true);
    try {
      final rows = await _loanService.getHistory(_selectedLoanEmployeeId!);
      if (!mounted) return;
      setState(() {
        _loanHistory = rows;
        _loanHistoryLoading = false;
      });
    } on ApiException {
      if (mounted) setState(() => _loanHistoryLoading = false);
    }
  }

  Future<void> _openRecordRepayment() async {
    final employee = _selectedLoanEmployee;
    if (employee == null) return;
    final result = await showLoanRepaymentDialog(context, employeeName: employee.employeeName);
    if (result == null || !mounted) return;
    try {
      await _loanService.createRepayment(EmployeeLoanRepayment(
        employeeId: employee.employeeId,
        repaymentDate: result.repaymentDate,
        amount: result.amount,
        paymentMode: result.paymentMode,
        remarks: result.remarks,
      ));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Repayment recorded. Cash ledger updated.')));
      _loadLoanSummary();
      _loadLoanHistory();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _deleteRepayment(EmployeeLoanHistoryRow row) async {
    if (row.employeeLoanRepaymentId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Repayment'),
        content: const Text('Delete this repayment? The cash ledger will be reversed automatically.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _loanService.deleteRepayment(row.employeeLoanRepaymentId!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Repayment deleted and cash ledger updated.')));
      _loadLoanSummary();
      _loadLoanHistory();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _openAdjustLoan() async {
    final employee = _selectedLoanEmployee;
    if (employee == null) return;
    final result = await showBalanceAdjustmentDialog(context, entityName: employee.employeeName);
    if (result == null || !mounted) return;
    try {
      await _loanService.applyAdjustment(employee.employeeId, amount: result.amount, isIncrease: result.isIncrease, narration: result.narration);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Loan adjustment applied.')));
      _loadLoanSummary();
      _loadLoanHistory();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _deleteAdjustment(EmployeeLoanHistoryRow row) async {
    if (row.employeeLoanAdjustmentId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Adjustment'),
        content: const Text('Delete this loan adjustment?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _loanService.deleteAdjustment(row.employeeLoanAdjustmentId!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Adjustment deleted.')));
      _loadLoanSummary();
      _loadLoanHistory();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Salary Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Work Log'), Tab(text: 'Loan Management')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildWorkLogTab(), _buildLoanTab()],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, _) => _tabController.index == 0
            ? FloatingActionButton.extended(
                onPressed: _openNewLog,
                icon: const Icon(Icons.add),
                label: const Text('New Entry'),
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildWorkLogTab() {
    final dateFormat = DateFormat('dd-MMM-yyyy');
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Column(
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
    );
  }

  Widget _buildLoanTab() {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final dateFormat = DateFormat('dd-MMM-yyyy');
    final selected = _selectedLoanEmployee;

    return RefreshIndicator(
      onRefresh: _loadLoanSummary,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          if (_loanLoading) const LinearProgressIndicator(),
          if (!_loanLoading && _loanSummary.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Column(
                children: [
                  Icon(Icons.account_balance_wallet_outlined, size: 48),
                  SizedBox(height: 12),
                  Center(child: Text("No active loans. Everyone's paid within salary.")),
                ],
              ),
            )
          else
            for (final row in _loanSummary)
              ListTile(
                selected: row.employeeId == _selectedLoanEmployeeId,
                title: Text(row.employeeName),
                subtitle: Text('${currencyFormat.format(row.salaryAmount)} / ${row.salaryType == 'Daily' ? 'day' : 'month'}'),
                trailing: Text(
                  currencyFormat.format(row.outstandingLoan),
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.red),
                ),
                onTap: () => _selectLoanEmployee(row.employeeId),
              ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text('Employee Loan Detail', style: Theme.of(context).textTheme.titleMedium),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Autocomplete<EmployeeOption>(
              textEditingController: _loanEmployeeController,
              focusNode: _loanEmployeeFocusNode,
              displayStringForOption: (e) => e.fullName,
              optionsBuilder: (value) {
                final query = value.text.trim().toLowerCase();
                if (query.isEmpty) return _employees;
                return _employees.where((e) => e.fullName.toLowerCase().contains(query));
              },
              onSelected: (e) => _selectLoanEmployee(e.employeeId),
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) => TextFormField(
                controller: controller,
                focusNode: focusNode,
                decoration: const InputDecoration(labelText: 'Select Employee'),
              ),
            ),
          ),
          if (selected != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected.outstandingLoan > 0 ? Colors.red.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Outstanding Loan: ${currencyFormat.format(selected.outstandingLoan)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: selected.outstandingLoan > 0 ? Colors.red : Colors.green,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _openAdjustLoan,
                      icon: const Icon(Icons.tune),
                      label: const Text('Adjust Loan'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _openRecordRepayment,
                      icon: const Icon(Icons.add),
                      label: const Text('Record Repayment'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (_loanHistoryLoading) const LinearProgressIndicator(),
            if (!_loanHistoryLoading && _loanHistory.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: Text('No loan activity for this employee.')),
              )
            else
              for (final row in _loanHistory)
                ListTile(
                  title: Text(row.particulars),
                  subtitle: Text(dateFormat.format(row.transactionDate)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            row.debit > 0 ? currencyFormat.format(row.debit) : (row.credit > 0 ? '-${currencyFormat.format(row.credit)}' : '—'),
                            style: TextStyle(fontWeight: FontWeight.w600, color: row.credit > 0 ? Colors.green : Colors.red),
                          ),
                          Text('Bal: ${currencyFormat.format(row.runningBalance)}', style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                      if (row.employeeLoanRepaymentId != null)
                        IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _deleteRepayment(row)),
                      if (row.employeeLoanAdjustmentId != null)
                        IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _deleteAdjustment(row)),
                    ],
                  ),
                ),
          ],
        ],
      ),
    );
  }
}
