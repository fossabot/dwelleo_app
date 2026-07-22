import '../../../../core/errors/api_result.dart';
import '../entities/project.dart';
import '../repositories/home_repository.dart';

/// Full project page data — VERIFIED GET /projects/{id}.
class GetProjectDetail {
  final HomeRepository _repository;

  const GetProjectDetail(this._repository);

  Future<ApiResult<Project>> call(int id) => _repository.getProject(id);
}
