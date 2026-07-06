import 'dart:async';

import 'package:dio/dio.dart';

import '../../constants/api_endpoints.dart';
import '../../constants/app_constants.dart';
import '../../storage/secure_storage.dart';

/// Handles token injection and transparent refresh.
///
/// Concurrent 401s share a single [Completer] so only one refresh happens
/// at a time; all waiting callers receive the new token via the completer
/// and retry independently — none are silently dropped.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage, this._refreshDio);

  final SecureStorage _storage;
  final Dio _refreshDio;

  Completer<String>? _refreshCompleter;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    // Avoid infinite loop if the refresh request itself 401s.
    if (err.requestOptions.path == ApiEndpoints.refreshToken) {
      await _storage.clearAuth();
      handler.next(err);
      return;
    }

    // A refresh is already in-flight — wait for the new token then retry.
    final existing = _refreshCompleter;
    if (existing != null) {
      try {
        final newToken = await existing.future;
        final opts = err.requestOptions
          ..headers['Authorization'] = 'Bearer $newToken';
        handler.resolve(await _refreshDio.fetch(opts));
      } catch (_) {
        handler.next(err);
      }
      return;
    }

    // This caller owns the refresh cycle.
    final completer = Completer<String>();
    _refreshCompleter = completer;
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null) {
        await _storage.clearAuth();
        completer.completeError('no_refresh_token');
        handler.next(err);
        return;
      }

      final response = await _refreshDio.post<Map<String, dynamic>>(
        ApiEndpoints.refreshToken,
        data: {'refresh_token': refreshToken},
      );

      final newAccess = response.data?[AppConstants.accessTokenKey] as String?;
      final newRefresh =
          response.data?[AppConstants.refreshTokenKey] as String?;
      if (newAccess == null) {
        throw Exception('Missing access_token in refresh response');
      }

      await _storage.setAccessToken(newAccess);
      if (newRefresh != null) await _storage.setRefreshToken(newRefresh);

      completer.complete(newAccess);

      final opts = err.requestOptions
        ..headers['Authorization'] = 'Bearer $newAccess';
      handler.resolve(await _refreshDio.fetch(opts));
    } catch (_) {
      if (!completer.isCompleted) {
        await _storage.clearAuth();
        completer.completeError('refresh_failed');
      }
      handler.next(err);
    } finally {
      if (_refreshCompleter == completer) {
        _refreshCompleter = null;
      }
    }
  }
}
