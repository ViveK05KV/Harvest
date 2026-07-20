/// Minimal shop shape used by dropdowns (from GET /shopmaster/active).
class ShopOption {
  final int shopId;
  final String shopName;

  const ShopOption({required this.shopId, required this.shopName});

  factory ShopOption.fromJson(Map<String, dynamic> json) {
    return ShopOption(
      shopId: json['shopID'] as int,
      shopName: json['shopName'] as String,
    );
  }
}
