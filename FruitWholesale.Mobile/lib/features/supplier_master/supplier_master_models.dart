class SupplierMaster {
  final int supplierId;
  final String supplierName;
  final String? phone;
  final String? address;
  final double openingBalance;
  final bool isActive;
  final double currentOutstanding;

  /// Reverse of ShopMaster.linkedSupplierId — the shop (if any) linked to this supplier.
  final int? linkedShopId;
  final String? linkedShopName;

  /// Linked shop's outstanding minus this supplier's own outstanding; meaningless when not linked.
  final double netBalance;

  const SupplierMaster({
    this.supplierId = 0,
    required this.supplierName,
    this.phone,
    this.address,
    this.openingBalance = 0,
    this.isActive = true,
    this.currentOutstanding = 0,
    this.linkedShopId,
    this.linkedShopName,
    this.netBalance = 0,
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
      linkedShopId: json['linkedShopID'] as int?,
      linkedShopName: json['linkedShopName'] as String?,
      netBalance: (json['netBalance'] as num?)?.toDouble() ?? (json['currentOutstanding'] as num).toDouble(),
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
