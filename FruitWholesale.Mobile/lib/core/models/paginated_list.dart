/// Mirrors the backend's `PaginatedList<T>` envelope.
class PaginatedList<T> {
  final List<T> items;
  final int pageNumber;
  final int pageSize;
  final int totalCount;
  final int totalPages;
  final bool hasPreviousPage;
  final bool hasNextPage;

  const PaginatedList({
    required this.items,
    required this.pageNumber,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
    required this.hasPreviousPage,
    required this.hasNextPage,
  });

  factory PaginatedList.fromJson(Map<String, dynamic> json, T Function(Map<String, dynamic>) fromJsonT) {
    return PaginatedList(
      items: (json['items'] as List).map((e) => fromJsonT(e as Map<String, dynamic>)).toList(),
      pageNumber: json['pageNumber'] as int,
      pageSize: json['pageSize'] as int,
      totalCount: json['totalCount'] as int,
      totalPages: json['totalPages'] as int,
      hasPreviousPage: json['hasPreviousPage'] as bool,
      hasNextPage: json['hasNextPage'] as bool,
    );
  }
}
