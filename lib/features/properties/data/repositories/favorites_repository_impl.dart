import '../../../../core/errors/api_result.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/entities/property.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../datasources/favorites_local_data_source.dart';

/// Local SQLite favorites. Errors are caught at this data boundary and
/// surface as [CacheFailure] — saving must never crash browsing.
class FavoritesRepositoryImpl implements FavoritesRepository {
  final FavoritesLocalDataSource _local;

  const FavoritesRepositoryImpl(this._local);

  @override
  Future<ApiResult<List<Property>>> favorites() => _guard(_local.all);

  @override
  Future<ApiResult<Set<int>>> favoriteIds() => _guard(_local.ids);

  @override
  Future<ApiResult<bool>> toggle(Property property) => _guard(() async {
    final saved = await _local.ids();
    if (saved.contains(property.id)) {
      await _local.remove(property.id);
      return false;
    }
    await _local.upsert(property);
    return true;
  });

  @override
  Future<ApiResult<void>> remove(int propertyId) =>
      _guard(() => _local.remove(propertyId));

  Future<ApiResult<T>> _guard<T>(Future<T> Function() run) async {
    try {
      return ApiSuccess(await run());
    } catch (e) {
      return ApiError(CacheFailure('$e'));
    }
  }
}
