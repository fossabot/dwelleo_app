import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dwelleo_app/core/errors/api_result.dart';
import 'package:dwelleo_app/core/errors/failure.dart';
import 'package:dwelleo_app/core/lookup/lookup_service.dart';
import 'package:dwelleo_app/core/storage/secure_storage.dart';
import 'package:dwelleo_app/features/properties/domain/entities/page_info.dart';
import 'package:dwelleo_app/features/properties/domain/entities/property.dart';
import 'package:dwelleo_app/features/properties/domain/entities/property_page.dart';
import 'package:dwelleo_app/features/properties/domain/entities/property_query.dart';
import 'package:dwelleo_app/features/properties/domain/repositories/property_repository.dart';
import 'package:dwelleo_app/features/properties/domain/usecases/search_properties.dart';
import 'package:dwelleo_app/features/properties/presentation/cubit/type_counts_cache.dart';
import 'package:dwelleo_app/features/properties/presentation/cubit/type_counts_cubit.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// Counts every per-type search so the cache's effect on the fan-out is visible.
class _CountingRepo implements PropertyRepository {
  int searchCalls = 0;

  @override
  Future<ApiResult<PropertyPage>> searchProperties(PropertyQuery query) async {
    searchCalls++;
    return ApiSuccess(
      const PropertyPage(
        properties: <Property>[],
        pageInfo: PageInfo(
          total: 100,
          count: 20,
          perPage: 20,
          currentPage: 1,
          totalPages: 5,
        ),
      ),
    );
  }

  @override
  Future<ApiResult<List<Property>>> getProperties({
    PropertyQuery? query,
  }) async => const ApiSuccess([]);

  @override
  Future<ApiResult<Property>> getPropertyBySlug(String slug) async =>
      throw UnimplementedError();
}

/// Like [_CountingRepo] but errors for one property type, so the fan-out lands
/// only partially — exercising the "don't cache an incomplete strip" rule.
class _PartialRepo extends _CountingRepo {
  final int failTypeId;
  _PartialRepo(this.failTypeId);

  @override
  Future<ApiResult<PropertyPage>> searchProperties(PropertyQuery query) {
    if (query.propertyTypeIds.contains(failTypeId)) {
      searchCalls++;
      return Future.value(const ApiError(NetworkFailure()));
    }
    return super.searchProperties(query);
  }
}

/// Serves a two-type `/lookup` payload without touching the network.
class _LookupAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    jsonEncode({
      'data': {
        'property_types': [
          {'id': 1, 'name': 'Apartment'},
          {'id': 2, 'name': 'Villa'},
        ],
      },
    }),
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}

/// Locale fake so `_syncLocale` never hits the platform keychain.
class _FakeStorage extends SecureStorage {
  _FakeStorage(this._locale) : super(const FlutterSecureStorage());
  String _locale;
  @override
  Future<String?> getLocale() async => _locale;
}

LookupService _lookup() {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
    ..httpClientAdapter = _LookupAdapter();
  return LookupService(dio, _FakeStorage('en'));
}

void main() {
  group('TypeCountsCubit + TypeCountsCache', () {
    test('populates the strip on the first load', () async {
      final repo = _CountingRepo();
      final cache = TypeCountsCache(_FakeStorage('en'));
      final cubit = TypeCountsCubit(SearchProperties(repo), _lookup(), cache);

      await cubit.load();

      // One request per headline type (two here), the strip filled.
      expect(repo.searchCalls, 2);
      expect(cubit.state.map((c) => c.name), ['Apartment', 'Villa']);
      await cubit.close();
    });

    test(
      'a second screen-open serves from cache with zero new searches',
      () async {
        final cache = TypeCountsCache(_FakeStorage('en'));

        final repo1 = _CountingRepo();
        final first = TypeCountsCubit(
          SearchProperties(repo1),
          _lookup(),
          cache,
        );
        await first.load();
        expect(repo1.searchCalls, 2);
        await first.close();

        // New screen => new cubit + repo, same shared session cache.
        final repo2 = _CountingRepo();
        final second = TypeCountsCubit(
          SearchProperties(repo2),
          _lookup(),
          cache,
        );
        await second.load();

        expect(repo2.searchCalls, 0, reason: 'cache hit must skip the fan-out');
        expect(second.state.map((c) => c.name), ['Apartment', 'Villa']);
        await second.close();
      },
    );

    test(
      'does NOT cache a partial fan-out, so the next visit retries',
      () async {
        final cache = TypeCountsCache(_FakeStorage('en'));

        // Villa (id 2) errors → the strip is incomplete on the first open.
        final repo1 = _PartialRepo(2);
        final first = TypeCountsCubit(
          SearchProperties(repo1),
          _lookup(),
          cache,
        );
        await first.load();
        expect(repo1.searchCalls, 2);
        expect(first.state.map((c) => c.name), ['Apartment']);
        await first.close();

        // Second open must re-run the fan-out — a partial result was not cached.
        final repo2 = _CountingRepo();
        final second = TypeCountsCubit(
          SearchProperties(repo2),
          _lookup(),
          cache,
        );
        await second.load();

        expect(
          repo2.searchCalls,
          2,
          reason: 'partial result must not be cached',
        );
        expect(second.state.map((c) => c.name), ['Apartment', 'Villa']);
        await second.close();
      },
    );

    test('forceRefresh re-runs the fan-out even on a cache hit', () async {
      final cache = TypeCountsCache(_FakeStorage('en'));
      final repo = _CountingRepo();
      final cubit = TypeCountsCubit(SearchProperties(repo), _lookup(), cache);

      await cubit.load();
      expect(repo.searchCalls, 2);

      // A cached hit would skip the fan-out; forceRefresh must not.
      await cubit.load(forceRefresh: true);
      expect(repo.searchCalls, 4);
      await cubit.close();
    });

    test('two concurrent plain loads share a single fan-out', () async {
      final repo = _CountingRepo();
      final cache = TypeCountsCache(_FakeStorage('en'));
      final cubit = TypeCountsCubit(SearchProperties(repo), _lookup(), cache);

      // Fire both before either resolves — the second must join the first.
      await Future.wait([cubit.load(), cubit.load()]);

      expect(
        repo.searchCalls,
        2,
        reason: 'in-flight load must be joined, not duplicated',
      );
      await cubit.close();
    });

    test(
      'a forceRefresh during an in-flight load serializes, never overlaps',
      () async {
        final repo = _CountingRepo();
        final cache = TypeCountsCache(_FakeStorage('en'));
        final cubit = TypeCountsCubit(SearchProperties(repo), _lookup(), cache);

        // Initial load + a refresh fired before it resolves: they run one after
        // the other (2 fan-outs = 4 searches), not concurrently, so the final
        // strip is the complete two-type result.
        await Future.wait([cubit.load(), cubit.load(forceRefresh: true)]);

        expect(repo.searchCalls, 4);
        expect(cubit.state.map((c) => c.name), ['Apartment', 'Villa']);
        await cubit.close();
      },
    );

    test('re-fetches after the language changes', () async {
      final storage = _FakeStorage('en');
      final cache = TypeCountsCache(storage);

      final repo1 = _CountingRepo();
      final first = TypeCountsCubit(SearchProperties(repo1), _lookup(), cache);
      await first.load();
      expect(repo1.searchCalls, 2);
      await first.close();

      storage._locale = 'ar';

      final repo2 = _CountingRepo();
      final second = TypeCountsCubit(SearchProperties(repo2), _lookup(), cache);
      await second.load();

      expect(repo2.searchCalls, 2, reason: 'locale change must drop the cache');
      await second.close();
    });
  });
}
