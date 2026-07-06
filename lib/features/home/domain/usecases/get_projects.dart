import '../../../../core/errors/api_result.dart';
import '../entities/project.dart';
import '../repositories/home_repository.dart';

/// Lists development projects for Home's "Explore Projects by Cities" section
/// and the Explore tab. UI -> Cubit -> this -> repository.
class GetProjects {
  final HomeRepository _repository;

  const GetProjects(this._repository);

  Future<ApiResult<List<Project>>> call() => _repository.getProjects();
}
