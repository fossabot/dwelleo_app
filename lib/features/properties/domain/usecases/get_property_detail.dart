import '../../../../core/errors/api_result.dart';
import '../entities/property.dart';
import '../repositories/property_repository.dart';

/// Fetches a single property's full detail by `slug`.
class GetPropertyDetail {
  final PropertyRepository _repository;

  const GetPropertyDetail(this._repository);

  Future<ApiResult<Property>> call(String slug) {
    return _repository.getPropertyBySlug(slug);
  }
}
