import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../domain/entities/property.dart';
import '../../domain/entities/property_page.dart';
import '../../domain/entities/property_query.dart';
import '../models/property_model.dart';

/// Talks to the real Dwelleo API. Throws [DioException] on transport/HTTP
/// errors; the repository maps those into typed Failures.
abstract interface class PropertyRemoteDataSource {
  /// Curated home/featured set (bare call, no pagination envelope).
  Future<List<Property>> getProperties({PropertyQuery? query});

  /// Paginated, filterable search — the `page` param switches the endpoint
  /// into search mode (contract re-verified live 2026-07-06).
  Future<PropertyPage> searchProperties(PropertyQuery query);

  Future<Property> getPropertyBySlug(String slug);
}

class PropertyRemoteDataSourceImpl implements PropertyRemoteDataSource {
  final Dio _dio;

  const PropertyRemoteDataSourceImpl(this._dio);

  @override
  Future<List<Property>> getProperties({PropertyQuery? query}) async {
    final res = await _dio.get<dynamic>(
      ApiEndpoints.properties,
      queryParameters: query == null ? null : toQueryParams(query),
      options: _listOptions(),
    );
    final body = _asMap(res.data);
    return body == null ? const [] : PropertyModel.listFromEnvelope(body);
  }

  @override
  Future<PropertyPage> searchProperties(PropertyQuery query) async {
    final res = await _dio.get<dynamic>(
      ApiEndpoints.properties,
      queryParameters: toQueryParams(query, paged: true),
      options: _listOptions(),
    );
    final body = _asMap(res.data) ?? const <String, dynamic>{};
    return PropertyModel.pageFromEnvelope(body);
  }

  @override
  Future<Property> getPropertyBySlug(String slug) async {
    final res = await _dio.get<dynamic>(ApiEndpoints.propertyBySlug(slug));
    final body = _asMap(res.data) ?? <String, dynamic>{};
    return PropertyModel.detailFromEnvelope(body);
  }

  /// `filter[property_types][]` must repeat per value — the backend 422s on
  /// comma-joined values ("must be an array"). ListFormat.multi repeats the
  /// key exactly as written.
  static Options _listOptions() => Options(listFormat: ListFormat.multi);

  /// Builds the real Spatie `filter[...]` query map from a domain query.
  /// Exposed for tests. NOTE: the singular `filter[property_type]` is a
  /// verified server-side no-op and is intentionally never sent.
  static Map<String, dynamic> toQueryParams(
    PropertyQuery q, {
    bool paged = false,
  }) {
    final p = <String, dynamic>{
      if (paged) PropertyFilters.page: q.page,
      PropertyFilters.sortCreatedAt: q.sort,
    };
    void put(String key, Object? value) {
      if (value != null) p[key] = value;
    }

    put(PropertyFilters.listingType, q.listingType);
    if (q.propertyTypeIds.isNotEmpty) {
      p[PropertyFilters.propertyTypesArray] = q.propertyTypeIds;
    }
    put(PropertyFilters.cityId, q.cityId);
    put(PropertyFilters.areaId, q.areaId);
    put(PropertyFilters.regionId, q.regionId);
    put(PropertyFilters.developerId, q.developerId);
    put(PropertyFilters.projectId, q.projectId);
    put(PropertyFilters.bedrooms, q.minBedrooms);
    put(PropertyFilters.bathrooms, q.minBathrooms);
    put(PropertyFilters.minPrice, q.minPrice);
    put(PropertyFilters.maxPrice, q.maxPrice);
    put(PropertyFilters.furnishingStatus, q.furnishingStatus);
    if (q.onlyFavorites == true) put(PropertyFilters.isFavorite, 1);
    return p;
  }

  static Map<String, dynamic>? _asMap(dynamic v) =>
      v is Map<String, dynamic> ? v : null;
}
