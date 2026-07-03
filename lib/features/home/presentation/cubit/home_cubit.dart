import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/api_result.dart';
import '../../../properties/domain/entities/property.dart';
import '../../../properties/domain/usecases/get_properties.dart';
import '../../domain/entities/developer.dart';
import '../../domain/entities/project.dart';
import '../../domain/usecases/get_featured_brokers.dart';
import '../../domain/usecases/get_featured_developers.dart';
import '../../domain/usecases/get_projects.dart';
import 'home_state.dart';

/// Loads the home feeds in parallel; each section succeeds or fails on
/// its own. Depends ONLY on use cases (never repositories) per project rules.
class HomeCubit extends Cubit<HomeState> {
  final GetProperties _getProperties;
  final GetProjects _getProjects;
  final GetFeaturedDevelopers _getFeaturedDevelopers;
  final GetFeaturedBrokers _getFeaturedBrokers;

  HomeCubit(
    this._getProperties,
    this._getProjects,
    this._getFeaturedDevelopers,
    this._getFeaturedBrokers,
  ) : super(const HomeState());

  /// Kicks off all sections concurrently. Completes when every feed settled.
  Future<void> load() {
    emit(const HomeState()); // all sections back to loading
    return Future.wait([
      _loadFeatured(),
      _loadProjects(),
      _loadDevelopers(),
      _loadBrokers(),
    ]);
  }

  Future<void> refresh() => load();

  Future<void> _loadFeatured() async {
    // Bare call = the API's curated home/featured set (REAL_API_SPEC §1).
    final result = await _getProperties();
    if (isClosed) return;
    emit(state.copyWith(featured: _section<List<Property>>(result)));
  }

  Future<void> _loadProjects() async {
    final result = await _getProjects();
    if (isClosed) return;
    emit(state.copyWith(projects: _section<List<Project>>(result)));
  }

  Future<void> _loadDevelopers() async {
    final result = await _getFeaturedDevelopers();
    if (isClosed) return;
    emit(state.copyWith(developers: _section<List<Developer>>(result)));
  }

  Future<void> _loadBrokers() async {
    final result = await _getFeaturedBrokers();
    if (isClosed) return;
    emit(state.copyWith(brokers: _section<List<Developer>>(result)));
  }

  static SectionState<T> _section<T>(ApiResult<T> result) => switch (result) {
    ApiSuccess<T>(:final data) => SectionLoaded<T>(data),
    ApiError<T>(:final failure) => SectionError<T>(failure),
  };
}
