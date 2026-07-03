import '../../../../core/errors/api_result.dart';
import '../entities/city_market_stat.dart';
import '../repositories/home_repository.dart';

/// District-level stats inside one city — the Interactive Market map's
/// "drop in" drill-down.
class GetMarketDistricts {
  final HomeRepository _repository;

  const GetMarketDistricts(this._repository);

  Future<ApiResult<List<MarketDistrict>>> call(int cityId, MarketQuery query) =>
      _repository.getMarketDistricts(cityId, query);
}
