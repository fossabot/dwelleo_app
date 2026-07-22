import '../../../../core/errors/api_result.dart';
import '../entities/property.dart';
import '../repositories/favorites_repository.dart';

/// Favorites use cases (bundled like `forgot_password_usecases.dart`).
/// UI → Cubit → these → [FavoritesRepository]; widgets never touch storage.

class GetFavorites {
  final FavoritesRepository _repository;
  const GetFavorites(this._repository);

  Future<ApiResult<List<Property>>> call() => _repository.favorites();
}

class GetFavoriteIds {
  final FavoritesRepository _repository;
  const GetFavoriteIds(this._repository);

  Future<ApiResult<Set<int>>> call() => _repository.favoriteIds();
}

class ToggleFavorite {
  final FavoritesRepository _repository;
  const ToggleFavorite(this._repository);

  /// Returns the new state: true = now saved.
  Future<ApiResult<bool>> call(Property property) =>
      _repository.toggle(property);
}

class RemoveFavorite {
  final FavoritesRepository _repository;
  const RemoveFavorite(this._repository);

  Future<ApiResult<void>> call(int propertyId) =>
      _repository.remove(propertyId);
}
