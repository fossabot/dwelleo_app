import 'package:flutter_bloc/flutter_bloc.dart';

// Needed for the `.when` extension (ApiResultX) — extensions must be in scope.
import '../../../../core/errors/api_result.dart';
import '../../domain/usecases/get_projects.dart';
import 'explore_state.dart';

/// Projects browser (Explore tab): loads the full projects feed once, then
/// filters by city client-side — the real API exposes no confirmed project
/// filters (REAL_API_SPEC), so we never invent query params.
class ExploreCubit extends Cubit<ExploreState> {
  final GetProjects _getProjects;

  ExploreCubit(this._getProjects) : super(const ExploreInitial());

  Future<void> load() async {
    emit(const ExploreLoading());
    final result = await _getProjects();
    if (isClosed) return;
    result.when(
      success: (projects) => emit(ExploreLoaded(projects)),
      error: (failure) => emit(ExploreError(failure)),
    );
  }

  /// Select a city chip (null = All). No-op unless loaded.
  void selectCity(String? city) {
    final s = state;
    if (s is! ExploreLoaded) return;
    emit(s.copyWith(selectedCity: () => city));
  }
}
