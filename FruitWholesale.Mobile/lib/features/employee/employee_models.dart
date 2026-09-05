/// Matches SALARY_TYPES in the backend/Angular models.
const List<String> salaryTypes = ['Monthly', 'Daily'];

class Employee {
  final int employeeId;
  final String fullName;
  final String? phone;
  final String? address;
  final bool isActive;
  final String salaryType;
  final double salaryAmount;

  const Employee({
    this.employeeId = 0,
    required this.fullName,
    this.phone,
    this.address,
    this.isActive = true,
    this.salaryType = 'Monthly',
    this.salaryAmount = 0,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      employeeId: json['employeeID'] as int,
      fullName: json['fullName'] as String,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      isActive: json['isActive'] as bool,
      salaryType: json['salaryType'] as String? ?? 'Monthly',
      salaryAmount: (json['salaryAmount'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toSaveJson() => {
        'fullName': fullName,
        'phone': phone,
        'address': address,
        'salaryType': salaryType,
        'salaryAmount': salaryAmount,
      };
}
