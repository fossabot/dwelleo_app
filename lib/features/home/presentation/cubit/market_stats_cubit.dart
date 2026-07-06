import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/api_result.dart';
import '../../domain/entities/city_market_stat.dart';
import '../../domain/usecases/get_city_market_stats.dart';
import 'home_state.dart';

/// State for one market-stats surface (the City Intelligence table OR the
/// map — each owns an instance so their toggles stay independent, exactly
/// like the website).
class MarketStatsState {
  final MarketQuery query;
  final SectionState<List<CityMarketStat>> stats;

  const MarketStatsState({
    this.query = const MarketQuery(),
    this.stats = const SectionLoading(),
  });

  MarketStatsState copyWith({
    MarketQuery? query,
    SectionState<List<CityMarketStat>>? stats,
  }) {
    return MarketStatsState(
      query: query ?? this.query,
      stats: stats ?? this.stats,
    );
  }
}

/// Fetches `/market/cities` for the current Buy|Rent × Apartment|Villa
/// selection; combinations already fetched are served from an in-memory
/// cache so toggling back is instant.
class MarketStatsCubit extends Cubit<MarketStatsState> {
  final GetCityMarketStats _getCityMarketStats;

  MarketStatsCubit(this._getCityMarketStats) : super(const MarketStatsState());

  final Map<String, List<CityMarketStat>> _cache = {};

  Future<void> load() => _fetch(state.query);

  /// Pull-to-refresh: bypass the cache and re-fetch the current selection so
  /// the RefreshIndicator actually delivers fresh numbers.
  Future<void> refresh() => _fetch(state.query, force: true);

  Future<void> setUnitType(int unitTypeId) =>
      _fetch(state.query.copyWith(unitTypeId: unitTypeId));

  Future<void> setTransaction(MarketTransaction transaction) =>
      _fetch(state.query.copyWith(transaction: transaction));

  Future<void> _fetch(MarketQuery query, {bool force = false}) async {
    final cached = _cache[query.key];
    if (cached != null && !force) {
      emit(state.copyWith(query: query, stats: SectionLoaded(cached)));
      return;
    }
    emit(state.copyWith(query: query, stats: const SectionLoading()));
    final result = await _getCityMarketStats(query);
    if (isClosed || state.query != query) return; // stale response
    result.when(
      success: (data) {
        final sorted = [...data]..sort((a, b) => b.value.compareTo(a.value));
        _cache[query.key] = sorted;
        emit(state.copyWith(stats: SectionLoaded(sorted)));
      },
      error: (failure) => emit(state.copyWith(stats: SectionError(failure))),
    );
  }
}
