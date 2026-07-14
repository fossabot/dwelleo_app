import 'package:dwelleo_app/core/errors/api_result.dart';
import 'package:dwelleo_app/core/errors/failure.dart';
import 'package:dwelleo_app/core/utils/contact_launcher.dart';
import 'package:dwelleo_app/features/properties/data/datasources/property_remote_data_source.dart';
import 'package:dwelleo_app/features/properties/data/models/property_model.dart';
import 'package:dwelleo_app/features/properties/domain/entities/page_info.dart';
import 'package:dwelleo_app/features/properties/domain/entities/property.dart';
import 'package:dwelleo_app/features/properties/domain/entities/property_page.dart';
import 'package:dwelleo_app/features/properties/domain/entities/property_query.dart';
import 'package:dwelleo_app/features/properties/domain/repositories/property_repository.dart';
import 'package:dwelleo_app/features/properties/domain/usecases/search_properties.dart';
import 'package:dwelleo_app/features/properties/presentation/cubit/properties_cubit.dart';
import 'package:dwelleo_app/features/properties/presentation/cubit/properties_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('toQueryParams — verified live contract (2026-07-06)', () {
    test('paged search sends page + array-syntax property types', () {
      final params = PropertyRemoteDataSourceImpl.toQueryParams(
        const PropertyQuery(
          listingType: 'for-sale',
          propertyTypeIds: [1, 2],
          cityId: 11,
          minBedrooms: 3,
          minPrice: 500000,
          page: 4,
        ),
        paged: true,
      );

      expect(params['page'], 4);
      expect(params['filter[listing_type]'], 'for-sale');
      // ARRAY key — the backend 422s on comma-joined values.
      expect(params['filter[property_types][]'], [1, 2]);
      expect(params['filter[city_id]'], 11);
      expect(params['filter[bedrooms]'], 3);
      expect(params['filter[min_price]'], 500000);
      // The singular param is a verified server-side no-op — never sent.
      expect(params.containsKey('filter[property_type]'), isFalse);
    });

    test('curated (unpaged) call omits the page param', () {
      final params = PropertyRemoteDataSourceImpl.toQueryParams(
        const PropertyQuery(listingType: 'for-rent'),
      );
      expect(params.containsKey('page'), isFalse);
    });
  });

  group('PropertyModel.pageFromEnvelope', () {
    test('parses properties + pagination (search-mode envelope)', () {
      final page = PropertyModel.pageFromEnvelope({
        'message': null,
        'data': {
          'properties': [
            {'id': 7, 'slug': 's', 'title': 'T'},
          ],
          'pagination': {
            'total': 1912,
            'count': 20,
            'per_page': 20,
            'current_page': 3,
            'total_pages': 96,
          },
        },
      });

      expect(page.properties, hasLength(1));
      expect(page.pageInfo?.total, 1912);
      expect(page.pageInfo?.currentPage, 3);
      expect(page.pageInfo?.hasMore, isTrue);
    });

    test('hasMore is false on the last page', () {
      const info = PageInfo(
        total: 40,
        count: 20,
        perPage: 20,
        currentPage: 2,
        totalPages: 2,
      );
      expect(info.hasMore, isFalse);
    });
  });

  group('PropertiesCubit pagination', () {
    test('load → loadMore appends next page and de-duplicates', () async {
      final cubit = PropertiesCubit(SearchProperties(_PagedRepo()));
      await cubit.load(query: const PropertyQuery(listingType: 'for-sale'));

      var state = cubit.state as PropertiesLoaded;
      expect(state.properties.map((p) => p.id), [1, 2]);
      expect(state.hasMore, isTrue);

      await cubit.loadMore();
      state = cubit.state as PropertiesLoaded;
      // Page 2 returns [2, 3]; the duplicate id=2 must not repeat.
      expect(state.properties.map((p) => p.id), [1, 2, 3]);
      expect(state.hasMore, isFalse);

      // Further loadMore is a no-op on the last page.
      await cubit.loadMore();
      expect((cubit.state as PropertiesLoaded).properties.length, 3);
      await cubit.close();
    });

    test('loadMore failure keeps loaded items and stops the spinner', () async {
      final repo = _PagedRepo(failPage2: true);
      final cubit = PropertiesCubit(SearchProperties(repo));
      await cubit.load();
      await cubit.loadMore();

      final state = cubit.state as PropertiesLoaded;
      expect(state.properties.map((p) => p.id), [1, 2]);
      expect(state.loadingMore, isFalse);
      await cubit.close();
    });

    test('applyFilters resets to page 1 with the new query', () async {
      final repo = _PagedRepo();
      final cubit = PropertiesCubit(SearchProperties(repo));
      await cubit.load();
      await cubit.loadMore();
      await cubit.applyFilters(
        const PropertyQuery(propertyTypeIds: [2], page: 7),
      );

      expect(repo.lastQuery?.page, 1); // page reset regardless of input
      expect(repo.lastQuery?.propertyTypeIds, [2]);
      await cubit.close();
    });
  });

  group('ContactLauncher URL building', () {
    test('normalizes Saudi numbers for wa.me', () {
      expect(ContactLauncher.normalizeMsisdn('056 7 77 7390'), '966567777390');
      expect(
        ContactLauncher.normalizeMsisdn('+966 56 777 7390'),
        '966567777390',
      );
      expect(ContactLauncher.normalizeMsisdn('00966567777390'), '966567777390');
    });

    test('builds tel and wa.me URIs', () {
      expect(
        ContactLauncher.telUri('+966 56 777-7390').toString(),
        'tel:+966567777390',
      );
      expect(
        ContactLauncher.whatsAppUri('0567777390').toString(),
        'https://wa.me/966567777390',
      );
    });
  });
}

/// Two-page fake: page1 → ids [1,2], page2 → ids [2,3] (overlap on purpose).
class _PagedRepo implements PropertyRepository {
  final bool failPage2;
  PropertyQuery? lastQuery;

  _PagedRepo({this.failPage2 = false});

  @override
  Future<ApiResult<PropertyPage>> searchProperties(PropertyQuery query) async {
    lastQuery = query;
    if (query.page >= 2 && failPage2) {
      return const ApiError(NetworkFailure());
    }
    final ids = query.page == 1 ? [1, 2] : [2, 3];
    return ApiSuccess(
      PropertyPage(
        properties: [
          for (final id in ids) Property(id: id, slug: 's$id', title: 'T$id'),
        ],
        pageInfo: PageInfo(
          total: 3,
          count: 2,
          perPage: 2,
          currentPage: query.page,
          totalPages: 2,
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
      const ApiSuccess(Property(id: 1, slug: 'a', title: 'A'));
}
