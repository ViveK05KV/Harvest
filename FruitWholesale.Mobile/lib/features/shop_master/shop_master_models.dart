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
      };

  Map<String, dynamic> toUpdateJson() => {
        'shopName': shopName,
        'ownerName': ownerName,
        'phone': phone,
        'address': address,
        'creditLimit': creditLimit,
        'routeID': routeId,
      };
}
