import 'package:flutter/material.dart';

import '../collections/collection_models.dart' show paymentModes;

class LoanRepaymentResult {
  final DateTime repaymentDate;
  final double amount;
  final String paymentMode;
  final String? remarks;

  const LoanRepaymentResult({
    required this.repaymentDate,
    required this.amount,
    required this.paymentMode,
    this.remarks,
  });
}

/// Records cash received back from an employee against their outstanding
/// loan; posts as cash-in on the backend. Mirrors the web client's
/// "Record Repayment" dialog.
Future<LoanRepaymentResult?> showLoanRepaymentDialog(BuildContext context, {required String employeeName}) {
  return showDialog<LoanRepaymentResult>(
    context: context,
    builder: (context) => _LoanRepaymentDialog(employeeName: employeeName),
  );
}

class _LoanRepaymentDialog extends StatefulWidget {
  const _LoanRepaymentDialog({required this.employeeName});
  final String employeeName;

  @override
  State<_LoanRepaymentDialog> createState() => _LoanRepaymentDialogState();
}

class _LoanRepaymentDialogState extends State<_LoanRepaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _remarksController = TextEditingController();
  DateTime _date = DateTime.now();
  String _paymentMode = paymentModes.first;

  @override
  void dispose() {
    _amountController.dispose();
    _remarksController.dispose();
    super.dispose();
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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(LoanRepaymentResult(
      repaymentDate: _date,
      amount: double.parse(_amountController.text),
      paymentMode: _paymentMode,
      remarks: _remarksController.text.trim().isEmpty ? null : _remarksController.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Record Repayment — ${widget.employeeName}'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cash received back from this employee; posts as cash-in and reduces the outstanding loan.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  final amount = double.tryParse(v ?? '');
                  return (amount == null || amount <= 0) ? 'Enter an amount greater than zero' : null;
                },
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Date'),
                  child: Text('${_date.day.toString().padLeft(2, '0')}-${_date.month.toString().padLeft(2, '0')}-${_date.year}'),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _paymentMode,
                decoration: const InputDecoration(labelText: 'Payment Mode'),
                items: [for (final mode in paymentModes) DropdownMenuItem(value: mode, child: Text(mode))],
                onChanged: (value) => setState(() => _paymentMode = value!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _remarksController,
                decoration: const InputDecoration(labelText: 'Remarks'),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(onPressed: _submit, child: const Text('Save repayment')),
      ],
    );
  }
}
