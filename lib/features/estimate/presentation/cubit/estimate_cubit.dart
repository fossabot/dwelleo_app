import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/api_result.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/lookup/lookup_service.dart';
import '../../../home/domain/entities/city_market_stat.dart';
import '../../../home/domain/usecases/get_market_districts.dart';
import '../../domain/entities/estimate_models.dart';
import '../../domain/usecases/calculate_estimate.dart';
import '../../domain/usecases/save_estimate.dart';

/// Wizard phases. Six required steps like the site, plus its OPTIONAL
/// accuracy booster and the result view.
enum EstimateStep {
  purpose,
  location,
  propertyType,
  details,
  condition,
  features,
  boost,
  result,
}

sealed class EstimateState {
  const EstimateState();
}

/// Filling the wizard. [districts] populate after a city is picked; the
/// site's cascading City → District behaviour.
class EstimateEditing extends EstimateState {
  final EstimateStep step;
  final EstimateInput input;
  final List<CityOption> cities;
  final List<MarketDistrict> districts;
  final bool loadingDistricts;
  final Failure? failure;

  const EstimateEditing({
    this.step = EstimateStep.purpose,
    this.input = const EstimateInput(),
    this.cities = const [],
    this.districts = const [],
    this.loadingDistricts = false,
    this.failure,
  });

  /// Drives the percentage exactly like the website, which counts the SEVEN
  /// input steps (six required + the optional booster) and excludes the
  /// result view: 14 / 28 / 42 / 57 / 71 / 85 / 95%.
  double get progress =>
      ((step.index + 1) / EstimateStep.result.index).clamp(0.0, 1.0);

  /// Whether the current step's requirements are met (Next stays disabled
  /// until then, mirroring the site's gates).
  bool get canAdvance => switch (step) {
    EstimateStep.location => input.hasLocation,
    EstimateStep.details => input.hasRequiredDetails,
    _ => true,
  };

  EstimateEditing copyWith({
    EstimateStep? step,
    EstimateInput? input,
    List<CityOption>? cities,
    List<MarketDistrict>? districts,
    bool? loadingDistricts,
    Failure? Function()? failure,
  }) {
    return EstimateEditing(
      step: step ?? this.step,
      input: input ?? this.input,
      cities: cities ?? this.cities,
      districts: districts ?? this.districts,
      loadingDistricts: loadingDistricts ?? this.loadingDistricts,
      failure: failure == null ? this.failure : failure(),
    );
  }
}

/// Crunching the market numbers ("Analysing market data…" on the site).
class EstimateCalculating extends EstimateState {
  final EstimateInput input;
  const EstimateCalculating(this.input);
}

class EstimateReady extends EstimateState {
  final EstimateInput input;
  final EstimateResult result;
  const EstimateReady(this.input, this.result);
}

class EstimateFailed extends EstimateState {
  final EstimateInput input;
  final Failure failure;
  const EstimateFailed(this.input, this.failure);
}

/// Owns the wizard. Depends ONLY on use cases (+ the shared lookup service
/// for the city list), per the project's architecture rules.
class EstimateCubit extends Cubit<EstimateState> {
  final CalculateEstimate _calculate;
  final SaveEstimate _save;
  final GetMarketDistricts _getDistricts;
  final LookupService _lookup;

  EstimateCubit(this._calculate, this._save, this._getDistricts, this._lookup)
    : super(const EstimateEditing());

  EstimateEditing get _editing => switch (state) {
    EstimateEditing s => s,
    EstimateCalculating(:final input) => EstimateEditing(input: input),
    EstimateReady(:final input) => EstimateEditing(input: input),
    EstimateFailed(:final input) => EstimateEditing(input: input),
  };

  Future<void> loadCities() async {
    try {
      final cities = await _lookup.cities();
      if (isClosed) return;
      emit(_editing.copyWith(cities: cities));
    } catch (_) {
      if (isClosed) return;
      emit(_editing.copyWith(failure: () => const NetworkFailure()));
    }
  }

  /// City choice reloads the district list (the site clears the district
  /// whenever the city changes).
  Future<void> selectCity(int cityId, String name) async {
    final current = _editing;
    emit(
      current.copyWith(
        input: current.input.copyWith(
          cityId: () => cityId,
          cityName: () => name,
          districtId: () => null,
          districtName: () => null,
        ),
        districts: const [],
        loadingDistricts: true,
        failure: () => null,
      ),
    );

    final result = await _getDistricts(
      cityId,
      MarketQuery(unitTypeId: _editing.input.unitTypeId),
    );
    if (isClosed) return;
    result.when(
      success: (districts) => emit(
        _editing.copyWith(districts: districts, loadingDistricts: false),
      ),
      error: (failure) => emit(
        _editing.copyWith(loadingDistricts: false, failure: () => failure),
      ),
    );
  }

  void selectDistrict(int id, String name) => emit(
    _editing.copyWith(
      input: _editing.input.copyWith(
        districtId: () => id,
        districtName: () => name,
      ),
    ),
  );

  /// Any other field edit — the screen passes a transformed input.
  void update(EstimateInput input) => emit(_editing.copyWith(input: input));

  void goTo(EstimateStep step) => emit(_editing.copyWith(step: step));

  void next() {
    final current = _editing;
    if (!current.canAdvance) return;
    final index = current.step.index;
    if (index < EstimateStep.boost.index) {
      emit(current.copyWith(step: EstimateStep.values[index + 1]));
    }
  }

  void back() {
    final current = _editing;
    final index = current.step.index;
    if (index > 0) {
      emit(current.copyWith(step: EstimateStep.values[index - 1]));
    }
  }

  /// Runs the valuation and persists it (the owner's "effects the database").
  Future<void> calculate() async {
    final input = _editing.input;
    emit(EstimateCalculating(input));

    final result = await _calculate(input);
    if (isClosed) return;
    await result.when(
      success: (value) async {
        await _save(input, value);
        if (isClosed) return;
        emit(EstimateReady(input, value));
      },
      error: (failure) async => emit(EstimateFailed(input, failure)),
    );
  }

  /// "Start a new estimate" — the site's reset control.
  void reset() => emit(EstimateEditing(cities: _editing.cities));
}
