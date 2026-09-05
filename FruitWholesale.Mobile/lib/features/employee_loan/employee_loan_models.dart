/// Mirrors the backend's EmployeeLoanDtos.cs.
class EmployeeLoanSummaryRow {
  final int employeeId;
  final String employeeName;
  final String salaryType;
  final double salaryAmount;
  final double outstandingLoan;

  const EmployeeLoanSummaryRow({
    required this.employeeId,
    required this.employeeName,
    required this.salaryType,
    required this.salaryAmount,
    required this.outstandingLoan,
  });

  factory EmployeeLoanSummaryRow.fromJson(Map<String, dynamic> json) => EmployeeLoanSummaryRow(
        employeeId: json['employeeID'] as int,
        employeeName: json['employeeName'] as String,
        salaryType: json['salaryType'] as String,
        salaryAmount: (json['salaryAmount'] as num).toDouble(),
        outstandingLoan: (json['outstandingLoan'] as num).toDouble(),
      );
}

/// One row in an employee's loan history - either a synthetic "month's pay
/// exceeded salary" debit (computed live, never stored) or a real repayment/
/// adjustment. Rows arrive pre-sorted with RunningBalance already accumulated.
class EmployeeLoanHistoryRow {
  final DateTime transactionDate;
  final String particulars;
  final double debit;
  final double credit;
  final double runningBalance;
  final int? employeeLoanRepaymentId;
  final int? employeeLoanAdjustmentId;

  const EmployeeLoanHistoryRow({
    required this.transactionDate,
    required this.particulars,
    required this.debit,
    required this.credit,
    required this.runningBalance,
    this.employeeLoanRepaymentId,
    this.employeeLoanAdjustmentId,
  });

  factory EmployeeLoanHistoryRow.fromJson(Map<String, dynamic> json) => EmployeeLoanHistoryRow(
        transactionDate: DateTime.parse(json['transactionDate'] as String),
        particulars: json['particulars'] as String,
        debit: (json['debit'] as num).toDouble(),
        credit: (json['credit'] as num).toDouble(),
        runningBalance: (json['runningBalance'] as num).toDouble(),
        employeeLoanRepaymentId: json['employeeLoanRepaymentID'] as int?,
        employeeLoanAdjustmentId: json['employeeLoanAdjustmentID'] as int?,
      );
}

class EmployeeLoanRepayment {
  final int employeeLoanRepaymentId;
  final int employeeId;
  final DateTime repaymentDate;
  final double amount;
  final String paymentMode;
  final String? remarks;

  const EmployeeLoanRepayment({
    this.employeeLoanRepaymentId = 0,
    required this.employeeId,
    required this.repaymentDate,
    required this.amount,
    this.paymentMode = 'Cash',
    this.remarks,
  });

  Map<String, dynamic> toSaveJson() => {
        'employeeLoanRepaymentID': employeeLoanRepaymentId,
        'employeeID': employeeId,
        'repaymentDate': repaymentDate.toIso8601String(),
        'amount': amount,
        'paymentMode': paymentMode,
        'remarks': remarks,
      };
}
