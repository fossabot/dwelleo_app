import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dwelleo_app/core/lookup/lookup_service.dart';
import 'package:dwelleo_app/core/storage/secure_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// Counts how many times `/lookup` is actually fetched over the wire.
class _CountingAdapter implements HttpClientAdapter {
  int lookupCalls = 0;
  final String body;
  _CountingAdapter(this.body);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path.contains('lookup')) lookupCalls++;
    return ResponseBody.fromString(
      body,
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Locale fake so `_syncLocale` never touches the platform keychain.
class _FakeStorage extends SecureStorage {
  _FakeStorage(this._locale) : super(const FlutterSecureStorage());
  String _locale;
  @override
  Future<String?> getLocale() async => _locale;
}

String _lookupBody() => jsonEncode({
  'data': {
    'cities': [
      {'id': 1, 'name': 'Riyadh'},
    ],
    'property_types': [
      {'id': 1, 'name': 'Apartment'},
    ],
    'areas': [
      {'id': 21, 'name': 'Al Murabba', 'city_id': 1},
    ],
  },
});

void main() {
  group('LookupService', () {
    test('fetches /lookup ONCE for concurrent cities/types/areas', () async {
      // Regression: the endpoint returns every section in one payload, but
      // each getter used to issue its own GET — three round-trips on startup.
      final adapter = _CountingAdapter(_lookupBody());
      final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = adapter;
      final service = LookupService(dio, _FakeStorage('en'));

      final results = await Future.wait([
        service.cities(),
        service.propertyTypes(),
        service.areas(),
      ]);

      expect(adapter.lookupCalls, 1);
      expect((results[0] as List<CityOption>).single.name, 'Riyadh');
      expect((results[1] as List<PropertyTypeOption>).single.name, 'Apartment');
      expect((results[2] as List<AreaOption>).single.cityId, 1);
    });

    test('serves cached sections without re-fetching', () async {
      final adapter = _CountingAdapter(_lookupBody());
      final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = adapter;
      final service = LookupService(dio, _FakeStorage('en'));

      await service.cities();
      await service.cities();
      await service.propertyTypes();

      expect(adapter.lookupCalls, 1);
    });

    test('re-fetches after the locale changes', () async {
      final adapter = _CountingAdapter(_lookupBody());
      final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = adapter;
      final storage = _FakeStorage('en');
      final service = LookupService(dio, storage);

      await service.cities();
      storage._locale = 'ar';
      await service.cities();

      expect(adapter.lookupCalls, 2);
    });
  });
}
