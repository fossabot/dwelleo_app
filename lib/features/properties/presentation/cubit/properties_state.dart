import '../../domain/entities/page_info.dart';
import '../../domain/entities/property.dart';
import '../../domain/entities/property_query.dart';

sealed class PropertiesState {
  const PropertiesState();
}

class PropertiesInitial extends PropertiesState {
  const PropertiesInitial();
}

class PropertiesLoading extends PropertiesState {
  const PropertiesLoading();
}

class PropertiesLoaded extends PropertiesState {
  final List<Property> properties;

  /// Pagination envelope (null only if the backend omitted it).
  final PageInfo? pageInfo;

  /// True while the next page is being appended (footer spinner).
  final bool loadingMore;

  /// The query these results answer — drives the active-filter chips.
  final PropertyQuery query;

  const PropertiesLoaded(
    this.properties, {
    this.pageInfo,
    this.loadingMore = false,
    this.query = const PropertyQuery(),
  });

  bool get isEmpty => properties.isEmpty;
  bool get hasMore => pageInfo?.hasMore ?? false;

  PropertiesLoaded copyWith({
    List<Property>? properties,
    PageInfo? pageInfo,
    bool? loadingMore,
    PropertyQuery? query,
  }) {
    return PropertiesLoaded(
      properties ?? this.properties,
      pageInfo: pageInfo ?? this.pageInfo,
      loadingMore: loadingMore ?? this.loadingMore,
      query: query ?? this.query,
    );
  }
}

class PropertiesError extends PropertiesState {
  final String message;
  const PropertiesError(this.message);
}
