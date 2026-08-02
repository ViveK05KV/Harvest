import 'package:flutter/material.dart';

class BalanceAdjustmentResult {
  final double amount;
  final bool isIncrease;
  final String narration;

  const BalanceAdjustmentResult({required this.amount, required this.isIncrease, required this.narration});
}

/// Posts a manual correction to a shop's or supplier's ledger, mirroring the
/// web client's "Adjust Balance" dialog. Editing OpeningBalance directly
/// after creation wouldn't move CurrentOutstanding, since that figure is
/// always derived from the ledger, not that column.
Future<BalanceAdjustmentResult?> showBalanceAdjustmentDialog(BuildContext context, {required String entityName}) {
  return showDialog<BalanceAdjustmentResult>(
    context: context,
    builder: (context) => _BalanceAdjustmentDialog(entityName: entityName),
  );
}

class _BalanceAdjustmentDialog extends StatefulWidget {
  const _BalanceAdjustmentDialog({required this.entityName});
  final String entityName;

  @override
  State<_BalanceAdjustmentDialog> createState() => _BalanceAdjustmentDialogState();
}

class _BalanceAdjustmentDialogState extends State<_BalanceAdjustmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _narrationController = TextEditingController();
  bool _isIncrease = true;

  @override
  void dispose() {
    _amountController.dispose();
    _narrationController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(BalanceAdjustmentResult(
      amount: double.parse(_amountController.text),
      isIncrease: _isIncrease,
      narration: _narrationController.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Adjust Balance — ${widget.entityName}'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Posts a manual correction to this ledger. Use this only for corrections — every other balance movement is automatic.",
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 12),
              RadioListTile<bool>(
                contentPadding: EdgeInsets.zero,
                title: const Text('Increase balance owed'),
                value: true,
                groupValue: _isIncrease,
                onChanged: (v) => setState(() => _isIncrease = v!),
              ),
              RadioListTile<bool>(
                contentPadding: EdgeInsets.zero,
                title: const Text('Decrease balance owed'),
                value: false,
                groupValue: _isIncrease,
                onChanged: (v) => setState(() => _isIncrease = v!),
              ),
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
              TextFormField(
                controller: _narrationController,
                decoration: const InputDecoration(labelText: 'Narration / Reason'),
                maxLines: 2,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Narration is required' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(onPressed: _submit, child: const Text('Apply Adjustment')),
      ],
    );
  }
}
