import '../../../../core/errors/api_result.dart';
import '../entities/city_market_stat.dart';
import '../repositories/home_repository.dart';

/// Live SAR/m² (buy) or SAR/mo (rent) stats per city for the
/// "City Intelligence" table and the Interactive Market map.
class GetCityMarketStats {
  final HomeRepository _repository;

  const GetCityMarketStats(this._repository);

  Future<ApiResult<List<CityMarketStat>>> call(MarketQuery query) =>
      _repository.getCityMarketStats(query);
}
