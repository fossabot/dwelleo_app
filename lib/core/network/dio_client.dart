import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../constants/app_constants.dart';
import '../errors/api_result.dart';
import '../errors/failure.dart';
import 'interceptors/logging_interceptor.dart';

class DioClient {
  DioClient._();

  static Dio create({
    required List<Interceptor> interceptors,
    String? baseUrl,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? AppConfig.instance.apiBaseUrl,
        connectTimeout: const Duration(
          milliseconds: AppConstants.connectTimeout,
        ),
        receiveTimeout: const Duration(
          milliseconds: AppConstants.receiveTimeout,
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.addAll([...interceptors, LoggingInterceptor()]);

    return dio;
  }

  static ApiResult<T> handleDioException<T>(DioException e) {
    final statusCode = e.response?.statusCode;
    final message = _extractMessage(e);

    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout => ApiError(
        NetworkFailure('Request timed out'),
      ),
      DioExceptionType.connectionError => ApiError(const NetworkFailure()),
      DioExceptionType.badResponse => switch (statusCode) {
        401 => ApiError(const UnauthorizedFailure()),
        404 => ApiError(NotFoundFailure(message)),
        422 => ApiError(ValidationFailure(message)),
        _ => ApiError(ServerFailure(message, statusCode: statusCode)),
      },
      _ => ApiError(UnknownFailure(message)),
    };
  }

  static String _extractMessage(DioException e) {
    try {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        return (data['message'] ?? data['error'] ?? 'Server error').toString();
      }
    } catch (_) {}
    return e.message ?? 'An error occurred';
  }
}
