import 'package:dio/dio.dart';
import '../../storage/secure_storage.dart';

class LocaleInterceptor extends Interceptor {
  LocaleInterceptor(this._storage);

  final SecureStorage _storage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final locale = await _storage.getLocale() ?? 'en';
    options.headers['Accept-Language'] = locale;
    handler.next(options);
  }
}
