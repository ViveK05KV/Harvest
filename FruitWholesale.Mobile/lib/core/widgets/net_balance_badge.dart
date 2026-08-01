import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Green/red "Net Receivable"/"Net Payable" pill shown on Shop and Supplier
/// ledger screens, matching the badge on the web client's ledger toolbars.
class NetBalanceBadge extends StatelessWidget {
  const NetBalanceBadge({super.key, required this.netBalance, required this.tooltip});
  final double netBalance;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final isReceivable = netBalance >= 0;
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isReceivable ? const Color(0xFFE6F4EA) : const Color(0xFFFDECEA),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          '${isReceivable ? 'Net Receivable' : 'Net Payable'}: ${currency.format(netBalance.abs())}',
          style: TextStyle(
            color: isReceivable ? const Color(0xFF1E7B34) : const Color(0xFFC0392B),
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
