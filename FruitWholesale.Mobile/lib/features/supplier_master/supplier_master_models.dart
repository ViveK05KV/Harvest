class SupplierMaster {
  final int supplierId;
  final String supplierName;
  final String? phone;
  final String? address;
  final double openingBalance;
  final bool isActive;
  final double currentOutstanding;

  const SupplierMaster({
    this.supplierId = 0,
    required this.supplierName,
    this.phone,
    this.address,
    this.openingBalance = 0,
    this.isActive = true,
    this.currentOutstanding = 0,
  });

  factory SupplierMaster.fromJson(Map<String, dynamic> json) {
    return SupplierMaster(
      supplierId: json['supplierID'] as int,
      supplierName: json['supplierName'] as String,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      openingBalance: (json['openingBalance'] as num).toDouble(),
      isActive: json['isActive'] as bool,
      currentOutstanding: (json['currentOutstanding'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toCreateJson() => {
        'supplierName': supplierName,
        'phone': phone,
        'address': address,
        'openingBalance': openingBalance,
      };

  Map<String, dynamic> toUpdateJson() => {
        'supplierName': supplierName,
        'phone': phone,
        'address': address,
      };
}
