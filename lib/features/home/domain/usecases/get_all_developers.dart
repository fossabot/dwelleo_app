import '../../../../core/errors/api_result.dart';
import '../entities/developer.dart';
import '../repositories/home_repository.dart';

/// Full developers list (first page) for the Developers directory screen —
/// unlike [GetFeaturedDevelopers] there is NO featured-only business rule.
class GetAllDevelopers {
  final HomeRepository _repository;

  const GetAllDevelopers(this._repository);

  Future<ApiResult<List<Developer>>> call() => _repository.getDevelopers();
}
