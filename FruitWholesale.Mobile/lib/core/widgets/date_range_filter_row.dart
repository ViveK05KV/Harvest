import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Compact From/To date-range filter row for list screens. Either bound can
/// be left unset (null = no lower/upper bound); tapping a chip's clear icon
/// resets it. Mirrors the web app's per-list From/To date pickers.
class DateRangeFilterRow extends StatelessWidget {
  final DateTime? fromDate;
  final DateTime? toDate;
  final ValueChanged<DateTime?> onFromChanged;
  final ValueChanged<DateTime?> onToChanged;

  const DateRangeFilterRow({
    super.key,
    required this.fromDate,
    required this.toDate,
    required this.onFromChanged,
    required this.onToChanged,
  });

  static final _format = DateFormat('dd-MMM-yyyy');

  Future<void> _pick(BuildContext context, DateTime? current, ValueChanged<DateTime?> onChanged) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _DateChip(
              label: 'From',
              date: fromDate,
              onTap: () => _pick(context, fromDate, onFromChanged),
              onClear: fromDate != null ? () => onFromChanged(null) : null,
              format: _format,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _DateChip(
              label: 'To',
              date: toDate,
              onTap: () => _pick(context, toDate, onToChanged),
              onClear: toDate != null ? () => onToChanged(null) : null,
              format: _format,
            ),
          ),
        ],
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  final DateFormat format;

  const _DateChip({required this.label, required this.date, required this.onTap, required this.onClear, required this.format});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          suffixIcon: onClear != null
              ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: onClear)
              : const Icon(Icons.calendar_today, size: 18),
        ),
        child: Text(date != null ? format.format(date!) : 'Any', overflow: TextOverflow.ellipsis),
      ),
    );
  }
}
