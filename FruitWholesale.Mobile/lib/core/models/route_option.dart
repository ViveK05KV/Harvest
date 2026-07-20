/// Minimal route shape used by dropdowns (from GET /routemaster/active).
class RouteOption {
  final int routeId;
  final String routeName;

  const RouteOption({required this.routeId, required this.routeName});

  factory RouteOption.fromJson(Map<String, dynamic> json) {
    return RouteOption(
      routeId: json['routeID'] as int,
      routeName: json['routeName'] as String,
    );
  }
}
