import '../../../../core/errors/api_result.dart';
import '../entities/estimate_models.dart';
import '../repositories/estimate_repository.dart';

/// The user's saved estimates, newest first.
class GetEstimates {
  final EstimateRepository _repository;

  const GetEstimates(this._repository);

  Future<ApiResult<List<SavedEstimate>>> call() => _repository.all();
}
