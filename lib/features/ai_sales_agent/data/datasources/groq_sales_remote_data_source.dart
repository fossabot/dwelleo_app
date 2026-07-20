import 'package:dio/dio.dart';

import '../../../../core/config/app_config.dart';
import '../../domain/entities/sales_models.dart';
import 'sales_remote_data_source.dart';

/// FREE-tier adapter: Groq's OpenAI-compatible chat completions API
/// (https://console.groq.com/docs) running Llama. No credit card required.
///
/// SECURITY: own Dio instance — the app's shared Dio carries Dwelleo
/// auth/locale interceptors that must never reach a third-party host.
/// The key comes from `--dart-define` via [AppConfig.groqApiKey] and is
/// attached per-request, never logged.
class GroqSalesRemoteDataSource implements SalesRemoteDataSource {
  final Dio _dio;

  GroqSalesRemoteDataSource([Dio? dio])
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 45),
            ),
          );

  static const _url = 'https://api.groq.com/openai/v1/chat/completions';

  @override
  Future<String> generateText({
    required String systemPrompt,
    required List<SalesMessage> history,
    required String message,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      _url,
      options: Options(
        headers: {'Authorization': 'Bearer ${AppConfig.groqApiKey}'},
        contentType: 'application/json',
      ),
      data: {
        'model': AppConfig.groqModel,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          for (final m in history)
            {
              'role': m.role == SalesRole.user ? 'user' : 'assistant',
              'content': m.text,
            },
          {'role': 'user', 'content': message},
        ],
        'temperature': 0.4,
        'response_format': {'type': 'json_object'},
      },
    );
    final choices = response.data?['choices'];
    if (choices is! List || choices.isEmpty) return '';
    final first = choices.first;
    final msg = first is Map ? first['message'] : null;
    final content = msg is Map ? msg['content'] : null;
    return '${content ?? ''}'.trim();
  }
}
