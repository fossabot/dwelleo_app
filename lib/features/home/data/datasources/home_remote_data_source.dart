import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/utils/json_parse.dart';
import '../../domain/entities/city_market_stat.dart';
import '../../domain/entities/developer.dart';
import '../../domain/entities/project.dart';
import '../models/city_market_stat_model.dart';
import '../models/developer_model.dart';
import '../models/project_model.dart';

/// Talks to the real Dwelleo API for the home/explore feeds. Throws
/// [DioException] on transport/HTTP errors; the repository maps those into
/// typed Failures. All query params below were CAPTURED from live website
/// traffic (2026-07-02) — never invented.
abstract interface class HomeRemoteDataSource {
  Future<List<Project>> getProjects();

  /// VERIFIED: GET /projects/{id} returns the full project incl.
  /// key_features/overview/gallery.
  Future<Project?> getProject(int id);

  /// First page (server-fixed 20/page). The featured-in-home business rule
  /// lives in the GetFeaturedDevelopers use case, not here.
  Future<List<Developer>> getDevelopers();

  /// Brokerages via `filter[user_type]=broker`.
  Future<List<Developer>> getBrokers();

  Future<List<Developer>> getAgents();

  Future<List<CityMarketStat>> getCityMarketStats(MarketQuery query);

  Future<List<MarketDistrict>> getMarketDistricts(
    int cityId,
    MarketQuery query,
  );
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  final Dio _dio;

  const HomeRemoteDataSourceImpl(this._dio);

  @override
  Future<Project?> getProject(int id) async {
    final res = await _dio.get<dynamic>('${ApiEndpoints.projects}/$id');
    final body = res.data;
    if (body is! Map) return null;
    return ProjectModel.detailFromEnvelope(Map<String, dynamic>.from(body));
  }

  @override
  Future<List<Project>> getProjects() async {
    final res = await _dio.get<dynamic>(ApiEndpoints.projects);
    final body = JsonParse.asMap(res.data);
    return body == null ? const [] : ProjectModel.listFromEnvelope(body);
  }

  @override
  Future<List<Developer>> getDevelopers() async {
    final res = await _dio.get<dynamic>(ApiEndpoints.developers);
    final body = JsonParse.asMap(res.data);
    return body == null ? const [] : DeveloperModel.listFromEnvelope(body);
  }

  @override
  Future<List<Developer>> getBrokers() async {
    final res = await _dio.get<dynamic>(
      ApiEndpoints.developers,
      queryParameters: {PropertyFilters.userType: 'broker'},
    );
    final body = JsonParse.asMap(res.data);
    return body == null ? const [] : DeveloperModel.listFromEnvelope(body);
  }

  @override
  Future<List<Developer>> getAgents() async {
    final res = await _dio.get<dynamic>(
      ApiEndpoints.developers,
      queryParameters: {PropertyFilters.userType: 'agent'},
    );
    final body = JsonParse.asMap(res.data);
    return body == null ? const [] : DeveloperModel.listFromEnvelope(body);
  }

  @override
  Future<List<CityMarketStat>> getCityMarketStats(MarketQuery query) async {
    final res = await _dio.get<dynamic>(
      ApiEndpoints.marketCities,
      queryParameters: _marketParams(query),
    );
    final body = JsonParse.asMap(res.data);
    return body == null
        ? const []
        : CityMarketStatModel.listFromEnvelope(body, query: query);
  }

  @override
  Future<List<MarketDistrict>> getMarketDistricts(
    int cityId,
    MarketQuery query,
  ) async {
    final res = await _dio.get<dynamic>(
      ApiEndpoints.marketDistricts,
      queryParameters: {'city_id': cityId, ..._marketParams(query)},
    );
    final body = JsonParse.asMap(res.data);
    return body == null
        ? const []
        : CityMarketStatModel.districtsFromEnvelope(body, query: query);
  }

  static Map<String, dynamic> _marketParams(MarketQuery q) => {
    'unit_type_id': q.unitTypeId,
    'heatmap': 'price',
    'transaction_type': q.transaction.apiValue,
  };
}
