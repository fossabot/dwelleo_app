import '../../../../core/errors/api_result.dart';
import '../entities/market_insight.dart';

abstract class MarketInsightRepository {
  Future<ApiResult<MarketInsightSeries>> series(
    MarketInsightChart chart,
    MarketInsightFilters filters,
  );

  Future<ApiResult<MarketInsightLookups>> lookups();
}
