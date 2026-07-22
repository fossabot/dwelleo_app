import '../../../../core/errors/api_result.dart';
import '../entities/estimate_models.dart';

abstract class EstimateRepository {
  Future<ApiResult<int>> save(EstimateInput input, EstimateResult result);

  Future<ApiResult<List<SavedEstimate>>> all();

  Future<ApiResult<void>> delete(int id);
}
