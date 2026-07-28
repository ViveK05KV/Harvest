/// Transaction types that actually post to CashLedger (see
/// `Domain.Enums.LedgerTransactionTypes` on the backend), with distinct
/// display labels for the Cash Ledger type filter — Collection and
/// SupplierPayment must stay distinguishable since both appear in one list.
const cashLedgerTypeLabels = <String, String>{
  'OpeningBalance': 'Opening Balance',
  'Collection': 'Collection (from shop)',
  'SupplierPayment': 'Supplier Payment',
  'DailyExpense': 'Daily Expense',
  'EmployeeWorkLog': 'Employee Wages',
};

/// Shared shape for Shop and Supplier ledgers (debit/credit style).
class LedgerEntry {
  final int ledgerId;
  final DateTime transactionDate;
  final String transactionType;
  final double debit;
  final double credit;
  final double runningBalance;
  final String? narration;

  const LedgerEntry({
    required this.ledgerId,
    required this.transactionDate,
    required this.transactionType,
    required this.debit,
    required this.credit,
    required this.runningBalance,
    this.narration,
  });

  factory LedgerEntry.fromJson(Map<String, dynamic> json) {
    return LedgerEntry(
      ledgerId: json['ledgerID'] as int,
      transactionDate: DateTime.parse(json['transactionDate'] as String),
      transactionType: json['transactionType'] as String,
      debit: (json['debit'] as num).toDouble(),
      credit: (json['credit'] as num).toDouble(),
      runningBalance: (json['runningBalance'] as num).toDouble(),
      narration: json['narration'] as String?,
    );
  }
}

class CashLedgerEntry {
  final int cashLedgerId;
  final DateTime transactionDate;
  final String transactionType;
  final String paymentMode;
  final double cashIn;
  final double cashOut;
  final double runningBalance;
  final String? narration;

  const CashLedgerEntry({
    required this.cashLedgerId,
    required this.transactionDate,
    required this.transactionType,
    required this.paymentMode,
    required this.cashIn,
    required this.cashOut,
    required this.runningBalance,
    this.narration,
  });

  factory CashLedgerEntry.fromJson(Map<String, dynamic> json) {
    return CashLedgerEntry(
      cashLedgerId: json['cashLedgerID'] as int,
      transactionDate: DateTime.parse(json['transactionDate'] as String),
      transactionType: json['transactionType'] as String,
      paymentMode: json['paymentMode'] as String,
      cashIn: (json['cashIn'] as num).toDouble(),
      cashOut: (json['cashOut'] as num).toDouble(),
      runningBalance: (json['runningBalance'] as num).toDouble(),
      narration: json['narration'] as String?,
    );
  }
}
