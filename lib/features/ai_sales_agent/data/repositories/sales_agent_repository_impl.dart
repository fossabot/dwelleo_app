import 'package:dio/dio.dart';

import '../../../../core/errors/api_result.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/entities/sales_models.dart';
import '../../domain/repositories/sales_agent_repository.dart';
import '../../domain/usecases/send_sales_message.dart';
import '../datasources/sales_remote_data_source.dart';
import '../models/sales_reply_model.dart';

/// Adapter over [SalesRemoteDataSource] (Groq free-tier today). Errors are
/// caught HERE (data boundary) and mapped to typed [Failure]s; 429 = rate
/// limit keeps its status code so the UI can show the specific message.
class SalesAgentRepositoryImpl implements SalesAgentRepository {
  final SalesRemoteDataSource _remote;

  const SalesAgentRepositoryImpl(this._remote);

  @override
  Future<ApiResult<SalesReply>> send({
    required List<SalesMessage> history,
    required String message,
  }) async {
    try {
      final text = await _remote.generateText(
        systemPrompt: salesAgentSystemPrompt,
        history: history,
        message: message,
      );
      final reply = SalesReplyModel.fromModelText(text);
      if (reply.text.isEmpty) {
        return const ApiError(ServerFailure('Empty model response'));
      }
      return ApiSuccess(reply);
    } on DioException catch (e) {
      return ApiError(_map(e));
    } catch (e) {
      return ApiError(ServerFailure('$e'));
    }
  }

  Failure _map(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkFailure();
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        final data = e.response?.data;
        // OpenAI-compatible (Groq) errors carry `error.message`; some
        // providers use `error.status`. Fall back generically.
        String message = 'Model error';
        if (data is Map && data['error'] is Map) {
          final err = data['error'] as Map;
          message = '${err['status'] ?? err['message'] ?? 'error'}';
        }
        return ServerFailure(message, statusCode: code);
      default:
        return ServerFailure(e.message ?? 'Unexpected error');
    }
  }
}
