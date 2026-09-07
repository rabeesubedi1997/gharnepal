/// Laravel's default paginated-resource-collection envelope:
/// `{ data: [...], links: {...}, meta: { current_page, last_page, total, ... } }`.
class PaginatedResult<T> {
  PaginatedResult({required this.items, required this.currentPage, required this.lastPage, required this.total});

  factory PaginatedResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final meta = json['meta'] as Map<String, dynamic>? ?? const {};
    return PaginatedResult(
      items: (json['data'] as List<dynamic>? ?? const [])
          .map((item) => fromJson(item as Map<String, dynamic>))
          .toList(),
      currentPage: meta['current_page'] as int? ?? 1,
      lastPage: meta['last_page'] as int? ?? 1,
      total: meta['total'] as int? ?? 0,
    );
  }

  final List<T> items;
  final int currentPage;
  final int lastPage;
  final int total;

  bool get hasMore => currentPage < lastPage;
}
