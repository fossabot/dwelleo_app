import 'package:flutter_bloc/flutter_bloc.dart';

// Provides the ApiResult.when extension used below.
import '../../../../core/errors/api_result.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/entities/property.dart';
import '../../domain/usecases/favorites_usecases.dart';

/// Saved tab state (Dart 3 sealed, no codegen).
sealed class FavoritesState {
  const FavoritesState();
}

class FavoritesLoading extends FavoritesState {
  const FavoritesLoading();
}

class FavoritesLoaded extends FavoritesState {
  final List<Property> properties;
  const FavoritesLoaded(this.properties);
}

class FavoritesError extends FavoritesState {
  final Failure failure;
  const FavoritesError(this.failure);
}

/// Drives the Saved tab: local favorites with optimistic swipe-delete.
class FavoritesCubit extends Cubit<FavoritesState> {
  final GetFavorites _getFavorites;
  final RemoveFavorite _removeFavorite;

  FavoritesCubit(this._getFavorites, this._removeFavorite)
    : super(const FavoritesLoading());

  Future<void> load() async {
    emit(const FavoritesLoading());
    final result = await _getFavorites();
    if (isClosed) return;
    result.when(
      success: (properties) => emit(FavoritesLoaded(properties)),
      error: (failure) => emit(FavoritesError(failure)),
    );
  }

  /// Optimistic removal; reloads from the store on failure so the list
  /// never lies about what is saved.
  Future<void> remove(int propertyId) async {
    final current = state;
    if (current is FavoritesLoaded) {
      emit(
        FavoritesLoaded(
          current.properties
              .where((p) => p.id != propertyId)
              .toList(growable: false),
        ),
      );
    }
    final result = await _removeFavorite(propertyId);
    if (isClosed) return;
    if (result is ApiError) await load();
  }
}
