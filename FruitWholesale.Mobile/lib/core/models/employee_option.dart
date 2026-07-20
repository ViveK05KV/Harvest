/// Minimal employee shape used by dropdowns (from GET /employee/active).
class EmployeeOption {
  final int employeeId;
  final String fullName;

  const EmployeeOption({required this.employeeId, required this.fullName});

  factory EmployeeOption.fromJson(Map<String, dynamic> json) {
    return EmployeeOption(
      employeeId: json['employeeID'] as int,
      fullName: json['fullName'] as String,
    );
  }
}
