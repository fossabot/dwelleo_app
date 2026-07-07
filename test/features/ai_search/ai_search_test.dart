import 'package:dio/dio.dart';
import 'package:dwelleo_app/core/errors/api_result.dart';
import 'package:dwelleo_app/core/errors/failure.dart';
import 'package:dwelleo_app/core/lookup/lookup_service.dart';
import 'package:dwelleo_app/features/ai_search/domain/usecases/interpret_ai_query.dart';
import 'package:dwelleo_app/features/ai_search/presentation/cubit/ai_search_cubit.dart';
import 'package:dwelleo_app/features/ai_search/presentation/cubit/ai_search_state.dart';
import 'package:dwelleo_app/features/properties/domain/entities/page_info.dart';
import 'package:dwelleo_app/features/properties/domain/entities/property.dart';
import 'package:dwelleo_app/features/properties/domain/entities/property_page.dart';
import 'package:dwelleo_app/features/properties/domain/entities/property_query.dart';
import 'package:dwelleo_app/features/properties/domain/repositories/property_repository.dart';
import 'package:dwelleo_app/features/properties/domain/usecases/search_properties.dart';
import 'package:flutter_test/flutter_test.dart';

// English-locale lookup options (as /lookup returns with Accept-Language: en).
const _typesEn = [
  PropertyTypeOption(id: 1, name: 'Apartment'),
  PropertyTypeOption(id: 2, name: 'Villa'),
  PropertyTypeOption(id: 4, name: 'Penthouse'),
  PropertyTypeOption(id: 8, name: 'office'),
];
const _citiesEn = [
  CityOption(id: '1', name: 'Riyadh'),
  CityOption(id: '11', name: 'Jeddah'),
  CityOption(id: '10', name: 'Makkah'),
];
// Arabic-locale lookup options (same ids, localized names).
const _typesAr = [
  PropertyTypeOption(id: 1, name: 'شقة'),
  PropertyTypeOption(id: 2, name: 'فيلا'),
];
const _citiesAr = [
  CityOption(id: '1', name: 'الرياض'),
  CityOption(id: '11', name: 'جدة'),
];

void main() {
  group('InterpretAiQuery.parse — EN input, EN lookups', () {
    test('site suggestion: "3 bedroom apartments in Riyadh"', () {
      final i = InterpretAiQuery.parse(
        '3 bedroom apartments in Riyadh',
        cities: _citiesEn,
        types: _typesEn,
      );
      expect(i.propertyType?.id, 1);
      expect(i.city?.id, '1');
      expect(i.minBedrooms, 3);
      expect(i.listingType, isNull);
      expect(i.hasSignal, isTrue);
    });

    test('site suggestion: "Cheapest villas for rent"', () {
      final i = InterpretAiQuery.parse(
        'Cheapest villas for rent',
        cities: _citiesEn,
        types: _typesEn,
      );
      expect(i.propertyType?.id, 2);
      expect(i.listingType, 'for-rent');
    });

    test('site suggestion: "Luxury penthouse above 10 million"', () {
      final i = InterpretAiQuery.parse(
        'Luxury penthouse above 10 million',
        cities: _citiesEn,
        types: _typesEn,
      );
      expect(i.propertyType?.id, 4);
      expect(i.minPrice, 10000000);
      expect(i.maxPrice, isNull);
    });

    test('office space matches the office type', () {
      final i = InterpretAiQuery.parse(
        'Office space in King Abdullah Financial District',
        cities: _citiesEn,
        types: _typesEn,
      );
      expect(i.propertyType?.id, 8);
    });

    test('"under 750k" becomes maxPrice 750000', () {
      final i = InterpretAiQuery.parse(
        'apartments in Jeddah under 750k',
        cities: _citiesEn,
        types: _typesEn,
      );
      expect(i.city?.id, '11');
      expect(i.maxPrice, 750000);
      expect(i.minPrice, isNull);
    });

    test('bare "500000 sar" budget maps to maxPrice', () {
      final i = InterpretAiQuery.parse(
        'apartment for 500000 sar',
        cities: _citiesEn,
        types: _typesEn,
      );
      expect(i.maxPrice, 500000);
    });

    test('bare "furnished" sets NO furnishing filter (unverified enum)', () {
      final i = InterpretAiQuery.parse(
        'Furnished apartments in Riyadh',
        cities: _citiesEn,
        types: _typesEn,
      );
      expect(i.furnishingStatus, isNull);
      expect(i.propertyType?.id, 1);
    });

    test('"unfurnished" maps to the verified enum value', () {
      final i = InterpretAiQuery.parse(
        'unfurnished apartment in Riyadh',
        cities: _citiesEn,
        types: _typesEn,
      );
      expect(i.furnishingStatus, 'unfurnished');
    });

    test('no real-estate signal → hasSignal false', () {
      final i = InterpretAiQuery.parse(
        'hello how are you today',
        cities: _citiesEn,
        types: _typesEn,
      );
      expect(i.hasSignal, isFalse);
    });
  });

  group('InterpretAiQuery.parse — cross-language bridging', () {
    test('AR utterance resolves against EN lookup names', () {
      final i = InterpretAiQuery.parse(
        'أرخص الفلل للإيجار في الرياض',
        cities: _citiesEn,
        types: _typesEn,
      );
      expect(i.propertyType?.id, 2, reason: 'الفلل → Villa via bridge');
      expect(i.city?.id, '1', reason: 'الرياض → Riyadh via bridge');
      expect(i.listingType, 'for-rent');
    });

    test('EN utterance resolves against AR lookup names', () {
      final i = InterpretAiQuery.parse(
        '3 bedroom apartments in Riyadh',
        cities: _citiesAr,
        types: _typesAr,
      );
      expect(i.propertyType?.id, 1, reason: 'apartments → شقة via bridge');
      expect(i.city?.id, '1');
    });

    test('Arabic-Indic digits and taa-marbuta fold correctly', () {
      final i = InterpretAiQuery.parse(
        'شقق ٣ غرف نوم في جده',
        cities: _citiesAr,
        types: _typesAr,
      );
      expect(i.minBedrooms, 3);
      expect(i.city?.id, '11', reason: 'جده matches جدة after folding');
    });

    test('site AR suggestion: "بنتهاوس فاخر بأكثر من 10 مليون"', () {
      final i = InterpretAiQuery.parse(
        'بنتهاوس فاخر بأكثر من 10 مليون',
        cities: _citiesEn,
        types: _typesEn,
      );
      expect(i.propertyType?.id, 4);
      expect(i.minPrice, 10000000);
    });
  });

  test('toQuery maps onto verified filter params only (page 1)', () {
    final i = InterpretAiQuery.parse(
      '2 bedroom villa for sale in Makkah under 2 million',
      cities: _citiesEn,
      types: _typesEn,
    );
    final q = i.toQuery();
    expect(q.listingType, 'for-sale');
    expect(q.propertyTypeIds, [2]);
    expect(q.cityId, 10);
    expect(q.minBedrooms, 2);
    expect(q.maxPrice, 2000000);
    expect(q.page, 1);
  });

  group('AiSearchCubit', () {
    test('submit → loading turn, then answer with total + capped preview',
        () async {
      final cubit = AiSearchCubit(
        _FakeInterpret(),
        SearchProperties(_StubRepo()),
      );
      await cubit.submit('3 bedroom apartments in Riyadh');
      final state = cubit.state;
      expect(state, isA<AiSearchChat>());
      final turn = (state as AiSearchChat).turns.single;
      expect(turn.loading, isFalse);
      expect(turn.answer, isNotNull);
      expect(turn.answer!.total, 43);
      expect(turn.answer!.preview.length, 3);
      await cubit.close();
    });

    test('no-signal utterance → unrecognized turn, no search call', () async {
      final repo = _StubRepo();
      final cubit = AiSearchCubit(_FakeInterpret(), SearchProperties(repo));
      await cubit.submit('hello');
      final turn = (cubit.state as AiSearchChat).turns.single;
      expect(turn.unrecognized, isTrue);
      expect(repo.searchCalls, 0);
      await cubit.close();
    });

    test('failure keeps the turn with a Failure; retry() recovers', () async {
      final repo = _StubRepo(failFirst: true);
      final cubit = AiSearchCubit(_FakeInterpret(), SearchProperties(repo));
      await cubit.submit('villas in Riyadh');
      var turn = (cubit.state as AiSearchChat).turns.single;
      expect(turn.failure, isA<NetworkFailure>());

      await cubit.retry();
      turn = (cubit.state as AiSearchChat).turns.single;
      expect(turn.failure, isNull);
      expect(turn.answer, isNotNull);
      await cubit.close();
    });

    test('reset returns to the welcome state', () async {
      final cubit = AiSearchCubit(_FakeInterpret(), SearchProperties(_StubRepo()));
      await cubit.submit('villas in Riyadh');
      cubit.reset();
      expect(cubit.state, isA<AiSearchIdle>());
      await cubit.close();
    });

    test('blank input is ignored', () async {
      final cubit = AiSearchCubit(_FakeInterpret(), SearchProperties(_StubRepo()));
      await cubit.submit('   ');
      expect(cubit.state, isA<AiSearchIdle>());
      await cubit.close();
    });
  });
}

/// Real interpreter over an offline fake lookup (EN names).
class _FakeInterpret extends InterpretAiQuery {
  _FakeInterpret() : super(_FakeLookup());
}

class _FakeLookup extends LookupService {
  _FakeLookup() : super(Dio());

  @override
  Future<List<CityOption>> cities() async => _citiesEn;

  @override
  Future<List<PropertyTypeOption>> propertyTypes() async => _typesEn;
}

class _StubRepo implements PropertyRepository {
  final bool failFirst;
  int searchCalls = 0;

  _StubRepo({this.failFirst = false});

  @override
  Future<ApiResult<PropertyPage>> searchProperties(PropertyQuery query) async {
    searchCalls++;
    if (failFirst && searchCalls == 1) {
      return const ApiError(NetworkFailure());
    }
    return ApiSuccess(
      PropertyPage(
        properties: [
          for (var id = 1; id <= 4; id++)
            Property(id: id, slug: 's$id', title: 'T$id'),
        ],
        pageInfo: PageInfo(
          total: 43,
          count: 4,
          perPage: 20,
          currentPage: query.page,
          totalPages: 3,
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
