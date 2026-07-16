import 'package:dio/dio.dart';

import '../../../../core/errors/api_result.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/entities/sales_models.dart';
import '../../domain/repositories/sales_agent_repository.dart';
import '../../domain/usecases/send_sales_message.dart';
import '../datasources/gemini_sales_remote_data_source.dart';
import '../models/sales_reply_model.dart';

/// Demo Gemini adapter. Errors are caught HERE (data boundary) and mapped to
/// typed [Failure]s; 429 = quota exhausted (observed live) keeps its status
/// code so the UI can show the specific "add credits" message.
class SalesAgentRepositoryImpl implements SalesAgentRepository {
  final GeminiSalesRemoteDataSource _remote;

  const SalesAgentRepositoryImpl(this._remote);

  @override
  Future<ApiResult<SalesReply>> send({
    required List<SalesMessage> history,
    required String message,
  }) async {
    try {
      final envelope = await _remote.generate(
        systemPrompt: salesAgentSystemPrompt,
        history: history,
        message: message,
      );
      final reply = SalesReplyModel.fromEnvelope(envelope);
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
        final message = (data is Map && data['error'] is Map)
            ? '${(data['error'] as Map)['status'] ?? 'error'}'
            : 'Gemini error';
        return ServerFailure(message, statusCode: code);
      default:
        return ServerFailure(e.message ?? 'Unexpected error');
    }
  }
}
