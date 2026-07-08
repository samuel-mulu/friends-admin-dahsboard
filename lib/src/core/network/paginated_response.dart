import 'pagination_meta.dart';

class PaginatedResponse<T> {
  PaginatedResponse({required this.items, required this.pagination});

  final List<T> items;
  final PaginationMeta pagination;
}
