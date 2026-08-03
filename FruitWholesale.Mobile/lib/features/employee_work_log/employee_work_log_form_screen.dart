import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/lookup_service.dart';
import '../../core/models/employee_option.dart';
import '../../core/models/route_option.dart';
import '../../core/utils/number_format_utils.dart';
import '../../core/widgets/date_picker_field.dart';
import '../../core/widgets/error_banner.dart';
import '../../core/widgets/save_footer_bar.dart';
import 'employee_work_log_models.dart';
import 'employee_work_log_service.dart';

class EmployeeWorkLogFormScreen extends StatefulWidget {
  final int? logId;

  const EmployeeWorkLogFormScreen({super.key, this.logId});

  bool get isEditing => logId != null;

  @override
  State<EmployeeWorkLogFormScreen> createState() => _EmployeeWorkLogFormScreenState();
}

class _EmployeeWorkLogFormScreenState extends State<EmployeeWorkLogFormScreen> {
  late final EmployeeWorkLogService _logService = EmployeeWorkLogService(context.read<ApiClient>());
  late final LookupService _lookupService = LookupService(context.read<ApiClient>());

  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _remarksController = TextEditingController();

  List<EmployeeOption> _employees = [];
  List<RouteOption> _routes = [];
  int? _selectedEmployeeId;
  int? _selectedRouteId;
  DateTime _date = DateTime.now();
  String _jobType = jobTypes.first;
  String _paymentMode = paymentModes.first;

  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final employeesFuture = _lookupService.getActiveEmployees();
      final routesFuture = _lookupService.getActiveRoutes();
      final employees = await employeesFuture;
      final routes = await routesFuture;

      if (widget.isEditing) {
        final log = await _logService.getById(widget.logId!);
        _selectedEmployeeId = log.employeeId;
        _selectedRouteId = log.routeId;
        _date = log.workDate;
        _jobType = log.jobType;
        _paymentMode = log.paymentMode;
        _amountController.text = trimZeros(log.amount);
        _remarksController.text = log.remarks ?? '';
      }

      setState(() {
        _employees = employees;
        _routes = routes;
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  EmployeeOption? _findEmployee(int? employeeId) {
    for (final employee in _employees) {
      if (employee.employeeId == employeeId) return employee;
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedEmployeeId == null) {
      setState(() => _error = 'Select an employee.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final log = EmployeeWorkLog(
      employeeWorkLogId: widget.logId ?? 0,
      workDate: _date,
      employeeId: _selectedEmployeeId!,
      jobType: _jobType,
      routeId: _selectedRouteId,
      amount: double.tryParse(_amountController.text) ?? 0,
      paymentMode: _paymentMode,
      remarks: _remarksController.text.trim().isEmpty ? null : _remarksController.text.trim(),
    );

    try {
      if (widget.isEditing) {
        await _logService.update(widget.logId!, log);
      } else {
        await _logService.create(log);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isEditing ? 'Edit Work Log' : 'New Work Log Entry')),
      body: _loading ? const Center(child: CircularProgressIndicator()) : _buildForm(),
      bottomNavigationBar: _loading ? null : SaveFooterBar(saving: _saving, onPressed: _save),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_error != null) ...[
            ErrorBanner(_error!),
            const SizedBox(height: 16),
          ],
          DatePickerField(date: _date, onChanged: (picked) => setState(() => _date = picked)),
          const SizedBox(height: 16),
          Autocomplete<EmployeeOption>(
            initialValue: TextEditingValue(text: _findEmployee(_selectedEmployeeId)?.fullName ?? ''),
            displayStringForOption: (employee) => employee.fullName,
            optionsBuilder: (value) {
              final query = value.text.trim().toLowerCase();
              if (query.isEmpty) return _employees;
              return _employees.where((employee) => employee.fullName.toLowerCase().contains(query));
            },
            onSelected: (employee) => setState(() => _selectedEmployeeId = employee.employeeId),
            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
              return TextFormField(
                controller: controller,
                focusNode: focusNode,
                decoration: const InputDecoration(labelText: 'Employee'),
              );
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _jobType,
            decoration: const InputDecoration(labelText: 'Job Type'),
            items: [for (final type in jobTypes) DropdownMenuItem(value: type, child: Text(type))],
            onChanged: (value) => setState(() => _jobType = value!),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int?>(
            initialValue: _selectedRouteId,
            decoration: const InputDecoration(labelText: 'Route (optional)'),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('None')),
              for (final route in _routes) DropdownMenuItem(value: route.routeId, child: Text(route.routeName)),
            ],
            onChanged: (value) => setState(() => _selectedRouteId = value),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _amountController,
            decoration: const InputDecoration(labelText: 'Salary Paid'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (v) {
              final amount = double.tryParse(v ?? '');
              if (amount == null || amount < 0) return 'Enter a valid amount';
              return null;
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _paymentMode,
            decoration: const InputDecoration(labelText: 'Payment Mode'),
            items: [for (final mode in paymentModes) DropdownMenuItem(value: mode, child: Text(mode))],
            onChanged: (value) => setState(() => _paymentMode = value!),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _remarksController,
            decoration: const InputDecoration(labelText: 'Remarks'),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

}
