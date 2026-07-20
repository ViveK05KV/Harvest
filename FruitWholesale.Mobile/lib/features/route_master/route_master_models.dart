class RouteMaster {
  final int routeId;
  final String routeName;
  final String? description;
  final bool isActive;
  final int shopCount;

  const RouteMaster({
    this.routeId = 0,
    required this.routeName,
    this.description,
    this.isActive = true,
    this.shopCount = 0,
  });

  factory RouteMaster.fromJson(Map<String, dynamic> json) {
    return RouteMaster(
      routeId: json['routeID'] as int,
      routeName: json['routeName'] as String,
      description: json['description'] as String?,
      isActive: json['isActive'] as bool,
      shopCount: json['shopCount'] as int,
    );
  }

  Map<String, dynamic> toSaveJson() => {
        'routeName': routeName,
        'description': description,
      };
}
