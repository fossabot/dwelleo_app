import '../../../../core/errors/api_result.dart';
import '../entities/city_market_stat.dart';
import '../entities/developer.dart';
import '../entities/project.dart';

/// Read-side contract for the home/explore surfaces. All feeds are public
/// (no auth) per REAL_API_SPEC — featured properties reuse the properties
/// feature's repository instead of duplicating it here.
abstract interface class HomeRepository {
  Future<ApiResult<List<Project>>> getProjects();

  Future<ApiResult<Project>> getProject(int id);

  /// Real-estate developers (the default /developers list).
  Future<ApiResult<List<Developer>>> getDevelopers();

  /// Brokerage companies — same endpoint with `filter[user_type]=broker`
  /// (captured from the website's "Top Real Estate Brokers" tab).
  Future<ApiResult<List<Developer>>> getBrokers();

  Future<ApiResult<List<Developer>>> getAgents();

  /// Per-city market stats for the given unit type + buy/rent side.
  Future<ApiResult<List<CityMarketStat>>> getCityMarketStats(MarketQuery query);

  /// Per-district stats inside one city (map drill-down).
  Future<ApiResult<List<MarketDistrict>>> getMarketDistricts(
    int cityId,
    MarketQuery query,
  );
}
