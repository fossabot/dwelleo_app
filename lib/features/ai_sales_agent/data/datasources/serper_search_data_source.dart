import 'package:dio/dio.dart';

import '../../../../core/config/app_config.dart';
import '../models/listing_result_model.dart';

/// Searches Google via Serper's API (https://serper.dev).
///
/// SECURITY: own Dio instance — the app's shared Dio carries Dwelleo
/// auth/locale interceptors that must never reach a third-party host.
/// The key comes from `--dart-define` via [AppConfig.serperApiKey] and
/// is sent per-request in a header, never logged.
class SerperSearchDataSource {
  final Dio _dio;

  SerperSearchDataSource([Dio? dio])
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 20),
              ),
            );

  static const _url = 'https://google.serper.dev/search';

  Future<List<ListingResultModel>> search(String query) async {
    final response = await _dio.post<Map<String, dynamic>>(
      _url,
      data: {'q': query, 'gl': 'sa', 'hl': 'ar', 'num': 5},
      options: Options(
        headers: {
          'X-API-KEY': AppConfig.serperApiKey,
          'Content-Type': 'application/json',
        },
      ),
    );
    final organic = (response.data?['organic'] as List<dynamic>?) ?? [];
    return organic
        .cast<Map<String, dynamic>>()
        .map(ListingResultModel.fromJson)
        .toList();
  }
}
