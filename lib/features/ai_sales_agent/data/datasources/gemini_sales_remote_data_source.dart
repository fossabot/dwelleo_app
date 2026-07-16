import 'package:dio/dio.dart';

import '../../../../core/config/app_config.dart';
import '../../domain/entities/sales_models.dart';

/// Direct REST adapter for Google Gemini `generateContent` (documented
/// public API — https://ai.google.dev/api). No SDK dependency: Dio only.
///
/// SECURITY: uses its OWN Dio instance — the app's shared Dio carries
/// Dwelleo auth/locale interceptors, and those headers must never be sent
/// to a third-party host. The key comes from `--dart-define` via
/// [AppConfig.geminiApiKey] and is attached per-request, never logged.
class GeminiSalesRemoteDataSource {
  final Dio _dio;

  GeminiSalesRemoteDataSource([Dio? dio])
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 45),
            ),
          );

  static const String _host = 'https://generativelanguage.googleapis.com';

  Future<Map<String, dynamic>> generate({
    required String systemPrompt,
    required List<SalesMessage> history,
    required String message,
  }) async {
    final model = AppConfig.geminiModel;
    final response = await _dio.post<Map<String, dynamic>>(
      '$_host/v1beta/models/$model:generateContent',
      options: Options(
        headers: {'x-goog-api-key': AppConfig.geminiApiKey},
        contentType: 'application/json',
      ),
      data: {
        'systemInstruction': {
          'parts': [
            {'text': systemPrompt},
          ],
        },
        'contents': [
          for (final m in history)
            {
              'role': m.role == SalesRole.user ? 'user' : 'model',
              'parts': [
                {'text': m.text},
              ],
            },
          {
            'role': 'user',
            'parts': [
              {'text': message},
            ],
          },
        ],
        'generationConfig': {
          'responseMimeType': 'application/json',
          'temperature': 0.4,
        },
      },
    );
    return response.data ?? const {};
  }
}
