import 'package:flutter_bloc/flutter_bloc.dart';

// api_result import required for the `.when` extension (ApiResultX).
import '../../../../core/errors/api_result.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/entities/property.dart';
import '../../domain/entities/property_query.dart';
import '../../domain/usecases/search_properties.dart';
import 'properties_state.dart';

/// Paginated, filterable property list over the verified search contract
/// (`/properties?page=N` + Spatie filters). Depends ONLY on use cases.
class PropertiesCubit extends Cubit<PropertiesState> {
  final SearchProperties _searchProperties;

  PropertiesCubit(this._searchProperties) : super(const PropertiesInitial());

  PropertyQuery _query = const PropertyQuery();
  PropertyQuery get query => _query;

  /// Full (re)load from page 1 with [query] (null = unfiltered catalog).
  Future<void> load({PropertyQuery? query}) async {
    _query = (query ?? const PropertyQuery()).withPage(1);
    emit(const PropertiesLoading());
    final result = await _searchProperties(_query);
    if (isClosed) return;
    result.when(
      success: (page) => emit(
        PropertiesLoaded(
          page.properties,
          pageInfo: page.pageInfo,
          query: _query,
        ),
      ),
      error: (failure) => emit(PropertiesError(_message(failure))),
    );
  }

  /// Replace the filter set (from the filters sheet / chips), resetting to
  /// page 1 while keeping the current listing type unless overridden.
  Future<void> applyFilters(PropertyQuery query) => load(query: query);

  /// Append the next page. No-op while loading, on the last page, or in a
  /// non-loaded state. De-duplicates by id (defensive against backend
  /// reshuffles between page fetches).
  Future<void> loadMore() async {
    final current = state;
    if (current is! PropertiesLoaded ||
        current.loadingMore ||
        !current.hasMore) {
      return;
    }
    emit(current.copyWith(loadingMore: true));
    final nextQuery = _query.withPage((current.pageInfo!.currentPage) + 1);
    final result = await _searchProperties(nextQuery);
    if (isClosed) return;
    result.when(
      success: (page) {
        _query = nextQuery;
        final seen = {for (final p in current.properties) p.id};
        final appended = <Property>[
          ...current.properties,
          ...page.properties.where((p) => seen.add(p.id)),
        ];
        emit(
          PropertiesLoaded(
            appended,
            pageInfo: page.pageInfo,
            query: _query,
          ),
        );
      },
      // Keep what the user has; just stop the footer spinner. Pull-to-
      // refresh remains the recovery path (site behaves the same).
      error: (_) => emit(current.copyWith(loadingMore: false)),
    );
  }

  Future<void> refresh() => load(query: _query);

  String _message(Failure failure) => switch (failure) {
    NetworkFailure() => 'No internet connection.',
    UnauthorizedFailure() => 'Please log in to continue.',
    NotFoundFailure() => 'No properties found.',
    ValidationFailure(:final message) => message,
    ServerFailure() => 'Server error. Please try again later.',
    _ => 'Something went wrong. Please try again.',
  };
}
