import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/api_result.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/entities/market_insight.dart';
import '../../domain/usecases/get_market_insight_lookups.dart';
import '../../domain/usecases/get_market_insight_series.dart';

class MarketInsightState {
  final MarketInsightChart chart;
  final MarketInsightFilters filters;
  final MarketInsightLookups lookups;

  /// Resolved series per chart — switching tabs is instant once fetched.
  final Map<MarketInsightChart, MarketInsightSeries> series;

  final bool loading;
  final Failure? failure;

  const MarketInsightState({
    this.chart = MarketInsightChart.topCitiesCommercialGrowth,
    this.filters = const MarketInsightFilters(),
    this.lookups = MarketInsightLookups.empty,
    this.series = const {},
    this.loading = false,
    this.failure,
  });

  MarketInsightSeries? get current => series[chart];

  MarketInsightState copyWith({
    MarketInsightChart? chart,
    MarketInsightFilters? filters,
    MarketInsightLookups? lookups,
    Map<MarketInsightChart, MarketInsightSeries>? series,
    bool? loading,
    Failure? Function()? failure,
  }) {
    return MarketInsightState(
      chart: chart ?? this.chart,
      filters: filters ?? this.filters,
      lookups: lookups ?? this.lookups,
      series: series ?? this.series,
      loading: loading ?? this.loading,
      failure: failure == null ? this.failure : failure(),
    );
  }
}

/// Owns the Market Insights screen. Depends only on use cases.
///
/// Charts are fetched lazily per tab and cached; changing a filter clears the
/// cache because every chart's rows depend on the same filter set (that's how
/// the website behaves — `filters_applied` echoes back on each response).
class MarketInsightCubit extends Cubit<MarketInsightState> {
  final GetMarketInsightSeries _getSeries;
  final GetMarketInsightLookups _getLookups;

  MarketInsightCubit(this._getSeries, this._getLookups)
    : super(const MarketInsightState());

  Future<void> load() async {
    await Future.wait([_loadLookups(), _fetch(state.chart)]);
  }

  Future<void> _loadLookups() async {
    final result = await _getLookups();
    if (isClosed) return;
    result.when(
      success: (lookups) => emit(state.copyWith(lookups: lookups)),
      // Filters are a nicety; losing them must not blank the charts.
      error: (_) {},
    );
  }

  Future<void> selectChart(MarketInsightChart chart) async {
    emit(state.copyWith(chart: chart, failure: () => null));
    if (state.series.containsKey(chart)) return;
    await _fetch(chart);
  }

  Future<void> applyFilters(MarketInsightFilters filters) async {
    emit(
      state.copyWith(filters: filters, series: const {}, failure: () => null),
    );
    await _fetch(state.chart);
  }

  Future<void> retry() => _fetch(state.chart);

  Future<void> _fetch(MarketInsightChart chart) async {
    emit(state.copyWith(loading: true, failure: () => null));
    final result = await _getSeries(chart, state.filters);
    if (isClosed) return;
    result.when(
      success: (series) => emit(
        state.copyWith(
          loading: false,
          series: {...state.series, chart: series},
        ),
      ),
      error: (failure) =>
          emit(state.copyWith(loading: false, failure: () => failure)),
    );
  }
}
