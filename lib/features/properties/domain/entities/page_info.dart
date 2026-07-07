import 'package:equatable/equatable.dart';

/// Pagination envelope of the property search — shape CONFIRMED live
/// (2026-07-06): `{total, count, per_page: 20 (server-fixed), current_page,
/// total_pages}`. Appears on `/properties` whenever `page` is sent.
class PageInfo extends Equatable {
  final int total;
  final int count;
  final int perPage;
  final int currentPage;
  final int totalPages;

  const PageInfo({
    required this.total,
    required this.count,
    required this.perPage,
    required this.currentPage,
    required this.totalPages,
  });

  bool get hasMore => currentPage < totalPages;

  @override
  List<Object?> get props => [total, count, perPage, currentPage, totalPages];
}
