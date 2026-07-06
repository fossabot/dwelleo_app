import 'package:dio/dio.dart';
import '../../config/app_config.dart';

class LoggingInterceptor extends Interceptor {
  static const _redactedKeys = {
    'authorization',
    'cookie',
    'set-cookie',
    'x-firebase-appcheck',
    'password',
    'otp',
    'code',
    'access_token',
    'refresh_token',
    'token',
  };

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final config = AppConfig.instance;
    switch (config.logLevel) {
      case AppLogLevel.verbose:
        final safeHeaders = _redactHeaders(options.headers);
        // ignore: avoid_print
        print('[NET][${config.flavorName}] --> ${options.method} '
            '${options.uri} headers:$safeHeaders');
      case AppLogLevel.standard:
        // ignore: avoid_print
        print('[NET][${config.flavorName}] --> ${options.method} '
            '${options.uri.path}');
      case AppLogLevel.minimal:
        break;
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final config = AppConfig.instance;
    switch (config.logLevel) {
      case AppLogLevel.verbose:
        // ignore: avoid_print
        print('[NET][${config.flavorName}] <-- ${response.statusCode} '
            '${response.requestOptions.uri}');
      case AppLogLevel.standard:
        // ignore: avoid_print
        print('[NET][${config.flavorName}] <-- ${response.statusCode} '
            '${response.requestOptions.path}');
      case AppLogLevel.minimal:
        break;
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final config = AppConfig.instance;
    switch (config.logLevel) {
      case AppLogLevel.verbose:
        // ignore: avoid_print
        print('[NET][${config.flavorName}] ERR ${err.response?.statusCode} '
            '${err.requestOptions.uri}: ${err.message}');
      case AppLogLevel.standard:
        // ignore: avoid_print
        print('[NET][${config.flavorName}] ERR ${err.response?.statusCode} '
            '${err.requestOptions.path}');
      case AppLogLevel.minimal:
        break;
    }
    handler.next(err);
  }

  Map<String, dynamic> _redactHeaders(Map<String, dynamic> headers) =>
      headers.map(
        (k, v) =>
            MapEntry(k, _redactedKeys.contains(k.toLowerCase()) ? '***' : v),
      );
}
