import '../../../../core/errors/failure.dart';
import '../../../properties/domain/entities/property.dart';
import '../../domain/entities/developer.dart';
import '../../domain/entities/project.dart';

/// Per-section async state. Home's feeds load in parallel and fail
/// independently — one broken section must never blank the whole screen
/// (same resilience the dwelleo.sa home page has).
sealed class SectionState<T> {
  const SectionState();
}

class SectionLoading<T> extends SectionState<T> {
  const SectionLoading();
}

class SectionLoaded<T> extends SectionState<T> {
  final T data;
  const SectionLoaded(this.data);
}

class SectionError<T> extends SectionState<T> {
  /// Typed failure — the widget layer maps it to a localized message.
  final Failure failure;
  const SectionError(this.failure);
}

/// Aggregate home state (market stats live in their own cubits so the
/// table and the map can filter independently, like the website).
/// `copyWith` keeps untouched sections as the SAME instances, so
/// `BlocSelector` on one section never rebuilds the others.
class HomeState {
  final SectionState<List<Property>> featured;
  final SectionState<List<Project>> projects;
  final SectionState<List<Developer>> developers;
  final SectionState<List<Developer>> brokers;

  const HomeState({
    this.featured = const SectionLoading(),
    this.projects = const SectionLoading(),
    this.developers = const SectionLoading(),
    this.brokers = const SectionLoading(),
  });

  HomeState copyWith({
    SectionState<List<Property>>? featured,
    SectionState<List<Project>>? projects,
    SectionState<List<Developer>>? developers,
    SectionState<List<Developer>>? brokers,
  }) {
    return HomeState(
      featured: featured ?? this.featured,
      projects: projects ?? this.projects,
      developers: developers ?? this.developers,
      brokers: brokers ?? this.brokers,
    );
  }
}
