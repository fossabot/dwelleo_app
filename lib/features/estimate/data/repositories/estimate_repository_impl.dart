import '../../../../core/errors/api_result.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/entities/estimate_models.dart';
import '../../domain/repositories/estimate_repository.dart';
import '../datasources/estimate_local_data_source.dart';

/// Local-storage adapter. Errors are caught HERE (data boundary) and mapped
/// to typed [Failure]s, per the project's error contract.
class EstimateRepositoryImpl implements EstimateRepository {
  final EstimateLocalDataSource _local;

  const EstimateRepositoryImpl(this._local);

  @override
  Future<ApiResult<int>> save(EstimateInput input, EstimateResult result) =>
      _guard(() => _local.save(input, result));

  @override
  Future<ApiResult<List<SavedEstimate>>> all() => _guard(_local.all);

  @override
  Future<ApiResult<void>> delete(int id) => _guard(() => _local.delete(id));

  Future<ApiResult<T>> _guard<T>(Future<T> Function() run) async {
    try {
      return ApiSuccess(await run());
    } catch (e) {
      return ApiError(CacheFailure('$e'));
    }
  }
}
