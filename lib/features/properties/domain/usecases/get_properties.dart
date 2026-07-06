import '../../../../core/errors/api_result.dart';
import '../entities/property.dart';
import '../entities/property_query.dart';
import '../repositories/property_repository.dart';

/// Lists/searches properties. UI -> Cubit -> this -> repository.
class GetProperties {
  final PropertyRepository _repository;

  const GetProperties(this._repository);

  Future<ApiResult<List<Property>>> call({PropertyQuery? query}) {
    return _repository.getProperties(query: query);
  }
}
