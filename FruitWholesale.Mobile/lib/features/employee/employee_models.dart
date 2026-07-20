class Employee {
  final int employeeId;
  final String fullName;
  final String? phone;
  final String? address;
  final bool isActive;

  const Employee({
    this.employeeId = 0,
    required this.fullName,
    this.phone,
    this.address,
    this.isActive = true,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      employeeId: json['employeeID'] as int,
      fullName: json['fullName'] as String,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      isActive: json['isActive'] as bool,
    );
  }

  Map<String, dynamic> toSaveJson() => {
        'fullName': fullName,
        'phone': phone,
        'address': address,
      };
}
