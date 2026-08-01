class ShopMaster {
  final int shopId;
  final String shopName;
  final String? ownerName;
  final String? phone;
  final String? address;
  final double openingBalance;
  final double creditLimit;
  final int? routeId;
  final String? routeName;
  final bool isActive;
  final double currentOutstanding;

  /// Optional link to a SupplierMaster row for a party that is both a shop and a supplier.
  final int? linkedSupplierId;
  final String? linkedSupplierName;

  /// currentOutstanding minus the linked supplier's outstanding; equals currentOutstanding when not linked.
  final double netBalance;

  const ShopMaster({
    this.shopId = 0,
    required this.shopName,
    this.ownerName,
    this.phone,
    this.address,
    this.openingBalance = 0,
    this.creditLimit = 0,
    this.routeId,
    this.routeName,
    this.isActive = true,
    this.currentOutstanding = 0,
    this.linkedSupplierId,
    this.linkedSupplierName,
    this.netBalance = 0,
  });

  factory ShopMaster.fromJson(Map<String, dynamic> json) {
    return ShopMaster(
      shopId: json['shopID'] as int,
      shopName: json['shopName'] as String,
      ownerName: json['ownerName'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      openingBalance: (json['openingBalance'] as num).toDouble(),
      creditLimit: (json['creditLimit'] as num).toDouble(),
      routeId: json['routeID'] as int?,
      routeName: json['routeName'] as String?,
      isActive: json['isActive'] as bool,
      currentOutstanding: (json['currentOutstanding'] as num).toDouble(),
      linkedSupplierId: json['linkedSupplierID'] as int?,
      linkedSupplierName: json['linkedSupplierName'] as String?,
      netBalance: (json['netBalance'] as num?)?.toDouble() ?? (json['currentOutstanding'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toCreateJson() => {
        'shopName': shopName,
        'ownerName': ownerName,
        'phone': phone,
        'address': address,
        'openingBalance': openingBalance,
        'creditLimit': creditLimit,
        'routeID': routeId,
        'linkedSupplierID': linkedSupplierId,
      };

  Map<String, dynamic> toUpdateJson() => {
        'shopName': shopName,
        'ownerName': ownerName,
        'phone': phone,
        'address': address,
        'creditLimit': creditLimit,
        'routeID': routeId,
        'linkedSupplierID': linkedSupplierId,
      };
}
