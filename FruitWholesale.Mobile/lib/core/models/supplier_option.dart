/// Minimal supplier shape used by dropdowns (from GET /suppliermaster/active).
class SupplierOption {
  final int supplierId;
  final String supplierName;

  const SupplierOption({required this.supplierId, required this.supplierName});

  factory SupplierOption.fromJson(Map<String, dynamic> json) {
    return SupplierOption(
      supplierId: json['supplierID'] as int,
      supplierName: json['supplierName'] as String,
    );
  }
}
