import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../domain/entities/property.dart';
import '../../domain/entities/property_query.dart';
import '../models/property_model.dart';

/// Talks to the real Dwelleo API. Throws [DioException] on transport/HTTP errors;
/// the repository maps those into typed Failures.
abstract interface class PropertyRemoteDataSource {
  Future<List<Property>> getProperties({PropertyQuery? query});
  Future<Property> getPropertyBySlug(String slug);
}

class PropertyRemoteDataSourceImpl implements PropertyRemoteDataSource {
  final Dio _dio;

  const PropertyRemoteDataSourceImpl(this._dio);

  @override
  Future<List<Property>> getProperties({PropertyQuery? query}) async {
    final res = await _dio.get<dynamic>(
      ApiEndpoints.properties,
      queryParameters: query == null ? null : _toQueryParams(query),
    );
    final body = _asMap(res.data);
    return body == null ? const [] : PropertyModel.listFromEnvelope(body);
  }

  @override
  Future<Property> getPropertyBySlug(String slug) async {
    final res = await _dio.get<dynamic>(ApiEndpoints.propertyBySlug(slug));
    final body = _asMap(res.data) ?? <String, dynamic>{};
    return PropertyModel.detailFromEnvelope(body);
  }

  /// Builds the real Spatie `filter[...]` query map from a domain query.
  static Map<String, dynamic> _toQueryParams(PropertyQuery q) {
    final p = <String, dynamic>{
      PropertyFilters.page: q.page,
      PropertyFilters.sortCreatedAt: q.sort,
    };
    void put(String key, Object? value) {
      if (value != null) p[key] = value;
    }

    put(PropertyFilters.listingType, q.listingType);
    put(PropertyFilters.propertyType, q.propertyTypeId);
    put(PropertyFilters.cityId, q.cityId);
    put(PropertyFilters.areaId, q.areaId);
    put(PropertyFilters.regionId, q.regionId);
    put(PropertyFilters.developerId, q.developerId);
    put(PropertyFilters.bedrooms, q.minBedrooms);
    put(PropertyFilters.bathrooms, q.minBathrooms);
    put(PropertyFilters.minPrice, q.minPrice);
    put(PropertyFilters.maxPrice, q.maxPrice);
    put(PropertyFilters.fromArea, q.minArea);
    put(PropertyFilters.toArea, q.maxArea);
    put(PropertyFilters.furnishingStatus, q.furnishingStatus);
    if (q.onlyFavorites == true) put(PropertyFilters.isFavorite, 1);
    return p;
  }

  static Map<String, dynamic>? _asMap(dynamic v) =>
      v is Map<String, dynamic> ? v : null;
}
