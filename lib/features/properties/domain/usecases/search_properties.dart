import '../../../../core/errors/api_result.dart';
import '../entities/property_page.dart';
import '../entities/property_query.dart';
import '../repositories/property_repository.dart';

/// Paginated, filterable property search (the website's 96-page catalog).
/// UI -> Cubit -> this -> repository.
class SearchProperties {
  final PropertyRepository _repository;

  const SearchProperties(this._repository);

  Future<ApiResult<PropertyPage>> call(PropertyQuery query) =>
      _repository.searchProperties(query);
}
