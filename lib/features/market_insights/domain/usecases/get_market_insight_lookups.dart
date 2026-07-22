import '../../../../core/errors/api_result.dart';
import '../entities/market_insight.dart';
import '../repositories/market_insight_repository.dart';

/// Filter options (regions, cities, unit types, purposes, years).
class GetMarketInsightLookups {
  final MarketInsightRepository _repository;

  const GetMarketInsightLookups(this._repository);

  Future<ApiResult<MarketInsightLookups>> call() => _repository.lookups();
}
