class FruitMaster {
  final int fruitId;
  final String fruitName;
  final String unit;
  final bool isActive;

  const FruitMaster({
    this.fruitId = 0,
    required this.fruitName,
    required this.unit,
    this.isActive = true,
  });

  factory FruitMaster.fromJson(Map<String, dynamic> json) {
    return FruitMaster(
      fruitId: json['fruitID'] as int,
      fruitName: json['fruitName'] as String,
      unit: json['unit'] as String,
      isActive: json['isActive'] as bool,
    );
  }

  Map<String, dynamic> toSaveJson() => {
        'fruitName': fruitName,
        'unit': unit,
      };
}
