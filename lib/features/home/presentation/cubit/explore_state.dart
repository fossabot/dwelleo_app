import '../../../../core/errors/failure.dart';
import '../../domain/entities/project.dart';

sealed class ExploreState {
  const ExploreState();
}

class ExploreInitial extends ExploreState {
  const ExploreInitial();
}

class ExploreLoading extends ExploreState {
  const ExploreLoading();
}

class ExploreLoaded extends ExploreState {
  /// Every project the API returned (source of truth for filtering).
  final List<Project> all;

  /// Selected city name, or null for "All". City names come localized from
  /// the API, so they double as chip labels (mirrors the website's chips).
  final String? selectedCity;

  const ExploreLoaded(this.all, {this.selectedCity});

  /// Distinct city names in first-seen order (Riyadh, Jeddah, … like the site).
  List<String> get cities {
    final seen = <String>{};
    return [
      for (final p in all)
        if (p.cityName != null && seen.add(p.cityName!)) p.cityName!,
    ];
  }

  /// Projects for the selected chip.
  List<Project> get filtered => selectedCity == null
      ? all
      : all.where((p) => p.cityName == selectedCity).toList(growable: false);

  ExploreLoaded copyWith({
    List<Project>? all,
    String? Function()? selectedCity,
  }) {
    return ExploreLoaded(
      all ?? this.all,
      selectedCity: selectedCity == null ? this.selectedCity : selectedCity(),
    );
  }
}

class ExploreError extends ExploreState {
  /// Typed failure — the widget layer maps it to a localized message.
  final Failure failure;
  const ExploreError(this.failure);
}
