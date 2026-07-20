export '../collections/collection_models.dart' show paymentModes;

/// Matches JOB_TYPES in the backend/Angular models.
const List<String> jobTypes = ['Supply', 'Collection', 'Loading', 'Other'];

/// Mirrors the backend's EmployeeWorkLog DTOs (EmployeeWorkLogDtos.cs).
class EmployeeWorkLog {
  final int employeeWorkLogId;
  final DateTime workDate;
  final int employeeId;
  final String? employeeName;
  final String jobType;
  final int? routeId;
  final String? routeName;
  final double amount;
  final String paymentMode;
  final String? remarks;

  const EmployeeWorkLog({
    this.employeeWorkLogId = 0,
    required this.workDate,
    required this.employeeId,
    this.employeeName,
    this.jobType = 'Supply',
    this.routeId,
    this.routeName,
    required this.amount,
    this.paymentMode = 'Cash',
    this.remarks,
  });

  factory EmployeeWorkLog.fromJson(Map<String, dynamic> json) {
    return EmployeeWorkLog(
      employeeWorkLogId: json['employeeWorkLogID'] as int,
      workDate: DateTime.parse(json['workDate'] as String),
      employeeId: json['employeeID'] as int,
      employeeName: json['employeeName'] as String?,
      jobType: json['jobType'] as String,
      routeId: json['routeID'] as int?,
      routeName: json['routeName'] as String?,
      amount: (json['amount'] as num).toDouble(),
      paymentMode: json['paymentMode'] as String,
      remarks: json['remarks'] as String?,
    );
  }

  Map<String, dynamic> toSaveJson() => {
        'employeeWorkLogID': employeeWorkLogId,
        'workDate': workDate.toIso8601String(),
        'employeeID': employeeId,
        'jobType': jobType,
        'routeID': routeId,
        'amount': amount,
        'paymentMode': paymentMode,
        'remarks': remarks,
      };
}
