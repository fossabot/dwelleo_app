import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../domain/entities/market_insight.dart';
import '../models/market_insight_model.dart';

/// Raw HTTP for the Market Insights charts. Throws — the repository maps
/// errors to typed Failures at the data boundary.
abstract class MarketInsightRemoteDataSource {
  Future<MarketInsightSeries> series(
    MarketInsightChart chart,
    MarketInsightFilters filters,
  );

  Future<MarketInsightLookups> lookups();
}

class MarketInsightRemoteDataSourceImpl
    implements MarketInsightRemoteDataSource {
  final Dio _dio;

  const MarketInsightRemoteDataSourceImpl(this._dio);

  @override
  Future<MarketInsightSeries> series(
    MarketInsightChart chart,
    MarketInsightFilters filters,
  ) async {
    final res = await _dio.get<dynamic>(
      ApiEndpoints.marketInsights(chart.path),
      queryParameters: filters.toQueryParams(),
    );
    final body = res.data;
    return MarketInsightModel.seriesFromEnvelope(
      body is Map ? body : const {},
      chart,
    );
  }

  @override
  Future<MarketInsightLookups> lookups() async {
    final res = await _dio.get<dynamic>(ApiEndpoints.marketInsightLookups);
    final body = res.data;
    return MarketInsightModel.lookupsFromEnvelope(
      body is Map ? body : const {},
    );
  }
}
