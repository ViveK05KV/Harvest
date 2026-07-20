import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/lookup_service.dart';
import '../../core/models/employee_option.dart';
import '../../core/models/route_option.dart';
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
      final employees = await _lookupService.getActiveEmployees();
      final routes = await _lookupService.getActiveRoutes();

      if (widget.isEditing) {
        final log = await _logService.getById(widget.logId!);
        _selectedEmployeeId = log.employeeId;
        _selectedRouteId = log.routeId;
        _date = log.workDate;
        _jobType = log.jobType;
        _paymentMode = log.paymentMode;
        _amountController.text = _trimZeros(log.amount);
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

  String _trimZeros(double value) {
    return value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toString();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _date = picked);
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
      bottomNavigationBar: _loading ? null : _buildFooter(),
    );
  }

  Widget _buildForm() {
    final scheme = Theme.of(context).colorScheme;
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_error != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: scheme.errorContainer, borderRadius: BorderRadius.circular(8)),
              child: Text(_error!, style: TextStyle(color: scheme.onErrorContainer)),
            ),
            const SizedBox(height: 16),
          ],
          InkWell(
            onTap: _pickDate,
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'Date', suffixIcon: Icon(Icons.calendar_today)),
              child: Text(DateFormat('dd-MMM-yyyy').format(_date)),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            initialValue: _selectedEmployeeId,
            decoration: const InputDecoration(labelText: 'Employee'),
            items: [
              for (final employee in _employees) DropdownMenuItem(value: employee.employeeId, child: Text(employee.fullName)),
            ],
            onChanged: (value) => setState(() => _selectedEmployeeId = value),
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

  Widget _buildFooter() {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: scheme.surface, border: Border(top: BorderSide(color: scheme.outlineVariant))),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save),
            label: const Text('Save'),
          ),
        ),
      ),
    );
  }
}
