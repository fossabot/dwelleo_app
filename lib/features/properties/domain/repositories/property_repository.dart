import '../../../../core/errors/api_result.dart';
import '../entities/property.dart';
import '../entities/property_page.dart';
import '../entities/property_query.dart';

abstract interface class PropertyRepository {
  /// List/search properties. With no [query], returns the curated home set.
  Future<ApiResult<List<Property>>> getProperties({PropertyQuery? query});

  /// Paginated, filterable search (`page` param, verified live 2026-07-06).
  Future<ApiResult<PropertyPage>> searchProperties(PropertyQuery query);

  /// Full detail for a single property by its `slug`.
  Future<ApiResult<Property>> getPropertyBySlug(String slug);
}
