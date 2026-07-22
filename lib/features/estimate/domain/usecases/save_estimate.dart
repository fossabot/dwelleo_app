import '../../../../core/errors/api_result.dart';
import '../entities/estimate_models.dart';
import '../repositories/estimate_repository.dart';

/// Persists a finished estimate (DB v3) so it survives the session.
class SaveEstimate {
  final EstimateRepository _repository;

  const SaveEstimate(this._repository);

  Future<ApiResult<int>> call(EstimateInput input, EstimateResult result) =>
      _repository.save(input, result);
}
