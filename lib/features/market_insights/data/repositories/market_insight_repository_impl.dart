import 'package:dio/dio.dart';

import '../../../../core/errors/api_result.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/market_insight.dart';
import '../../domain/repositories/market_insight_repository.dart';
import '../datasources/market_insight_remote_data_source.dart';

class MarketInsightRepositoryImpl implements MarketInsightRepository {
  final MarketInsightRemoteDataSource _remote;

  const MarketInsightRepositoryImpl(this._remote);

  @override
  Future<ApiResult<MarketInsightSeries>> series(
    MarketInsightChart chart,
    MarketInsightFilters filters,
  ) => _guard(() => _remote.series(chart, filters));

  @override
  Future<ApiResult<MarketInsightLookups>> lookups() => _guard(_remote.lookups);

  Future<ApiResult<T>> _guard<T>(Future<T> Function() run) async {
    try {
      return ApiSuccess(await run());
    } on DioException catch (e) {
      return DioClient.handleDioException<T>(e);
    } catch (e) {
      return ApiError(UnknownFailure('$e'));
    }
  }
}
