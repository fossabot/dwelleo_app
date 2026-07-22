import '../../../../core/errors/api_result.dart';
import '../entities/market_insight.dart';
import '../repositories/market_insight_repository.dart';

/// One chart's rows for the current filter selection.
class GetMarketInsightSeries {
  final MarketInsightRepository _repository;

  const GetMarketInsightSeries(this._repository);

  Future<ApiResult<MarketInsightSeries>> call(
    MarketInsightChart chart,
    MarketInsightFilters filters,
  ) => _repository.series(chart, filters);
}
