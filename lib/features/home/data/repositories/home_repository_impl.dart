import 'package:dio/dio.dart';

import '../../../../core/errors/api_result.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/city_market_stat.dart';
import '../../domain/entities/developer.dart';
import '../../domain/entities/project.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_remote_data_source.dart';

/// Catches data-layer exceptions at the boundary and maps them to typed
/// Failures — same contract as PropertyRepositoryImpl.
class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource _remote;

  HomeRepositoryImpl(this._remote);

  /// Coalesces concurrent identical city-stat requests into one network call:
  /// the home Table and Map cubits both load the same query on startup. Held
  /// only while in-flight and removed on completion, so pull-to-refresh always
  /// re-fetches fresh data.
  final Map<MarketQuery, Future<ApiResult<List<CityMarketStat>>>>
  _cityStatsInflight = {};

  @override
  Future<ApiResult<List<Project>>> getProjects() {
    return _guard(_remote.getProjects);
  }

  @override
  Future<ApiResult<Project>> getProject(int id) {
    return _guard(() async {
      final project = await _remote.getProject(id);
      if (project == null) throw const FormatException('project not found');
      return project;
    });
  }

  @override
  Future<ApiResult<List<Developer>>> getDevelopers() {
    return _guard(_remote.getDevelopers);
  }

  @override
  Future<ApiResult<List<Developer>>> getBrokers() {
    return _guard(_remote.getBrokers);
  }

  @override
  Future<ApiResult<List<Developer>>> getAgents() {
    return _guard(_remote.getAgents);
  }

  @override
  Future<ApiResult<List<CityMarketStat>>> getCityMarketStats(
    MarketQuery query,
  ) {
    final existing = _cityStatsInflight[query];
    if (existing != null) return existing;
    final future = _guard(() => _remote.getCityMarketStats(query));
    _cityStatsInflight[query] = future;
    future.whenComplete(() => _cityStatsInflight.remove(query));
    return future;
  }

  @override
  Future<ApiResult<List<MarketDistrict>>> getMarketDistricts(
    int cityId,
    MarketQuery query,
  ) {
    return _guard(() => _remote.getMarketDistricts(cityId, query));
  }

  Future<ApiResult<T>> _guard<T>(Future<T> Function() request) async {
    try {
      return ApiSuccess(await request());
    } on DioException catch (e) {
      return DioClient.handleDioException<T>(e);
    } catch (e) {
      return ApiError(UnknownFailure(e.toString()));
    }
  }
}
