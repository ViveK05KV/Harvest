/// Minimal fruit shape used by dropdowns (from GET /fruitmaster/active).
class FruitOption {
  final int fruitId;
  final String fruitName;
  final String unit;

  const FruitOption({required this.fruitId, required this.fruitName, required this.unit});

  factory FruitOption.fromJson(Map<String, dynamic> json) {
    return FruitOption(
      fruitId: json['fruitID'] as int,
      fruitName: json['fruitName'] as String,
      unit: json['unit'] as String,
    );
  }
}
