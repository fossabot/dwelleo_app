import '../../../../core/errors/api_result.dart';
import '../entities/property.dart';

/// Local favorites — the returning-user journey (review P0 #6). Local-first
/// so guests can save; syncing with the authed `filter[is_favorite]` backend
/// state layers on later behind this same contract.
abstract class FavoritesRepository {
  Future<ApiResult<List<Property>>> favorites();

  Future<ApiResult<Set<int>>> favoriteIds();

  /// Adds when absent, removes when present; returns the NEW state
  /// (true = now saved).
  Future<ApiResult<bool>> toggle(Property property);

  Future<ApiResult<void>> remove(int propertyId);
}
