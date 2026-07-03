import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/api_result.dart';
import '../../domain/entities/city_market_stat.dart';
import '../../domain/usecases/get_city_market_stats.dart';
import '../../domain/usecases/get_market_districts.dart';
import 'home_state.dart';

/// State for the Interactive Market map: city bubbles for the current
/// filters, plus an optional district drill-down for a focused city
/// (the website's "click any bubble to drop in").
class MarketMapState {
  final MarketQuery query;
  final SectionState<List<CityMarketStat>> cities;

  /// City the user drilled into (null = country view).
  final CityMarketStat? focusedCity;
  final SectionState<List<MarketDistrict>> districts;

  const MarketMapState({
    this.query = const MarketQuery(),
    this.cities = const SectionLoading(),
    this.focusedCity,
    this.districts = const SectionLoaded(<MarketDistrict>[]),
  });

  MarketMapState copyWith({
    MarketQuery? query,
    SectionState<List<CityMarketStat>>? cities,
    CityMarketStat? Function()? focusedCity,
    SectionState<List<MarketDistrict>>? districts,
  }) {
    return MarketMapState(
      query: query ?? this.query,
      cities: cities ?? this.cities,
      focusedCity: focusedCity == null ? this.focusedCity : focusedCity(),
      districts: districts ?? this.districts,
    );
  }
}

class MarketMapCubit extends Cubit<MarketMapState> {
  final GetCityMarketStats _getCityMarketStats;
  final GetMarketDistricts _getMarketDistricts;

  MarketMapCubit(this._getCityMarketStats, this._getMarketDistricts)
    : super(const MarketMapState());

  final Map<String, List<CityMarketStat>> _cityCache = {};
  final Map<String, List<MarketDistrict>> _districtCache = {};

  Future<void> load() => _fetchCities(state.query);

  Future<void> setUnitType(int unitTypeId) =>
      _applyQuery(state.query.copyWith(unitTypeId: unitTypeId));

  Future<void> setTransaction(MarketTransaction transaction) =>
      _applyQuery(state.query.copyWith(transaction: transaction));

  Future<void> _applyQuery(MarketQuery query) async {
    // New filters invalidate the current drill-down view's data; refetch
    // districts for the focused city (if any) alongside the cities.
    await Future.wait([
      _fetchCities(query),
      if (state.focusedCity != null) _fetchDistricts(state.focusedCity!, query),
    ]);
  }

  /// Drill into one city's districts.
  Future<void> focusCity(CityMarketStat city) =>
      _fetchDistricts(city, state.query);

  /// Back to the country-level bubbles.
  void clearFocus() {
    emit(
      state.copyWith(
        focusedCity: () => null,
        districts: const SectionLoaded(<MarketDistrict>[]),
      ),
    );
  }

  Future<void> _fetchCities(MarketQuery query) async {
    final cached = _cityCache[query.key];
    if (cached != null) {
      emit(state.copyWith(query: query, cities: SectionLoaded(cached)));
      return;
    }
    emit(state.copyWith(query: query, cities: const SectionLoading()));
    final result = await _getCityMarketStats(query);
    if (isClosed || state.query != query) return;
    result.when(
      success: (data) {
        _cityCache[query.key] = data;
        emit(state.copyWith(cities: SectionLoaded(data)));
      },
      error: (failure) => emit(state.copyWith(cities: SectionError(failure))),
    );
  }

  Future<void> _fetchDistricts(CityMarketStat city, MarketQuery query) async {
    final cacheKey = '${city.cityId}-${query.key}';
    final cached = _districtCache[cacheKey];
    emit(
      state.copyWith(
        query: query,
        focusedCity: () => city,
        districts: cached != null
            ? SectionLoaded(cached)
            : const SectionLoading(),
      ),
    );
    if (cached != null) return;
    final result = await _getMarketDistricts(city.cityId, query);
    if (isClosed || state.focusedCity?.cityId != city.cityId) return;
    result.when(
      success: (data) {
        _districtCache[cacheKey] = data;
        emit(state.copyWith(districts: SectionLoaded(data)));
      },
      error: (failure) =>
          emit(state.copyWith(districts: SectionError(failure))),
    );
  }
}
