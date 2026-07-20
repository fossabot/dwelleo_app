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
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 20),
            ),
          );

  static const _url = 'https://google.serper.dev/search';

  // Fix #3: hl is now a parameter (not hardcoded 'ar') so English sessions
  //   get English-ranked results.
  // Fix #6: whereType<> instead of cast<> — one bad entry is skipped rather
  //   than aborting the entire list with a CastError.
  Future<List<ListingResultModel>> search(String query, {String hl = 'ar'}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      _url,
      data: {'q': query, 'gl': 'sa', 'hl': hl, 'num': 5},
      options: Options(
        headers: {
          'X-API-KEY': AppConfig.serperApiKey,
          'Content-Type': 'application/json',
        },
      ),
    );
    final organic = (response.data?['organic'] as List<dynamic>?) ?? [];
    return organic
        .whereType<Map<String, dynamic>>()
        .map(ListingResultModel.fromJson)
        .toList();
  }
}
