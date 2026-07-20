import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A tappable "Date" form field that opens the platform date picker.
class DatePickerField extends StatelessWidget {
  final DateTime date;
  final ValueChanged<DateTime> onChanged;
  final String label;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const DatePickerField({
    super.key,
    required this.date,
    required this.onChanged,
    this.label = 'Date',
    this.firstDate,
    this.lastDate,
  });

  static final _format = DateFormat('dd-MMM-yyyy');

  Future<void> _pick(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: firstDate ?? DateTime(2020),
      lastDate: lastDate ?? DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _pick(context),
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, suffixIcon: const Icon(Icons.calendar_today)),
        child: Text(_format.format(date)),
      ),
    );
  }
}
