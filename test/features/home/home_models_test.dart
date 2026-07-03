import 'package:dwelleo_app/features/home/data/models/city_market_stat_model.dart';
import 'package:dwelleo_app/features/home/data/models/developer_model.dart';
import 'package:dwelleo_app/features/home/data/models/project_model.dart';
import 'package:dwelleo_app/features/home/domain/entities/city_market_stat.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fixtures mirror the LIVE payload shapes captured from website traffic
/// (2026-07-02) — see docs/api/REAL_API_SPEC.md and api_endpoints.dart.
void main() {
  group('ProjectModel', () {
    test('parses the {data:{projects:[...]}} envelope', () {
      final envelope = {
        'message': null,
        'data': {
          'projects': [
            {
              'id': 7,
              'slug': 'azyan-al-fursan',
              'name': 'Azyan Al Fursan',
              'image': {
                'id': 1,
                'path': 'https://s3/img.png',
                'path_thumbnail': 'https://s3/thumb.png',
                'mime_type': 'image/png',
              },
              'city': {'id': 1, 'name': 'Riyadh', 'title': 'الرياض'},
              'location_coordinates': {'lat': '24.7', 'lng': '46.6'},
              'starting_price': '325000',
              'is_off_plan': true,
              'developer': {'id': 3, 'name': 'Aknan', 'is_verified': 1},
            },
          ],
        },
      };

      final list = ProjectModel.listFromEnvelope(envelope);

      expect(list, hasLength(1));
      final p = list.first;
      expect(p.slug, 'azyan-al-fursan');
      expect(p.cityName, 'Riyadh');
      expect(p.coordinates?.lat, 24.7);
      // String numbers are tolerated like everywhere in the data layer.
      expect(p.startingPrice, 325000);
      expect(p.isOffPlan, isTrue);
      expect(p.developer?.isVerified, isTrue);
      expect(p.image?.displayThumb, 'https://s3/thumb.png');
    });

    test('returns empty list for a malformed envelope', () {
      expect(ProjectModel.listFromEnvelope({'data': null}), isEmpty);
      expect(ProjectModel.listFromEnvelope({'data': {}}), isEmpty);
    });
  });

  group('DeveloperModel', () {
    test('parses the {data:{developers:[...], pagination}} envelope', () {
      final envelope = {
        'message': null,
        'data': {
          'developers': [
            {
              'id': 260,
              'name': 'Maqam For Real estate',
              'image': {'id': 9, 'path': 'https://s3/maqam.png'},
              'rating': 0,
              'featured': true,
              'featuredInHome': true,
            },
            {
              'id': 291,
              'name': ' 1000  القاسم العقاريه ',
              'featured': false,
              'featuredInHome': false,
            },
          ],
          'pagination': {'total': 49, 'per_page': 20},
        },
      };

      final list = DeveloperModel.listFromEnvelope(envelope);

      expect(list, hasLength(2));
      expect(list.first.featuredInHome, isTrue);
      expect(list.first.image?.path, 'https://s3/maqam.png');
      // Live data contains names with stray spaces — model trims them.
      expect(list.last.name, '1000  القاسم العقاريه');
    });
  });

  group('CityMarketStatModel', () {
    const buyApartment = MarketQuery(); // apartment + buy (defaults)
    const rentApartment = MarketQuery(transaction: MarketTransaction.rent);

    test('parses the BUY shape (filtered_stats object, price_of_meter)', () {
      final envelope = {
        'success': true,
        'data': [
          {
            'city_id': 10,
            'name': 'Makkah',
            'lat': 21.3891,
            'lng': 39.8579,
            'overall': {
              'avg_price_per_meter': 5878.83,
              'avg_median_price': 6186.86,
            },
            'filtered_stats': {
              'unit_type_id': 1,
              'price_of_meter': 4614.58,
              'median': 4939.53,
            },
            'last_updated': '2026-05-07T13:17:01.000000Z',
          },
        ],
      };

      final list = CityMarketStatModel.listFromEnvelope(
        envelope,
        query: buyApartment,
      );

      expect(list, hasLength(1));
      // The exact number dwelleo.sa renders in its table.
      expect(list.first.value, 4614.58);
      expect(list.first.median, 4939.53);
    });

    test('parses the RENT shape (monthly_price)', () {
      final envelope = {
        'success': true,
        'data': [
          {
            'city_id': 2,
            'name': 'Al Kharj',
            'lat': 24.15,
            'lng': 47.3333,
            'overall': {
              'avg_monthly_price': 5740.7767,
              'avg_annual_price': 68889.32,
            },
            'filtered_stats': {
              'unit_type_id': 1,
              'monthly_price': 5740.7767,
              'annual_price': 68889.32,
              'median': 5740.7767,
            },
          },
        ],
      };

      final list = CityMarketStatModel.listFromEnvelope(
        envelope,
        query: rentApartment,
      );

      expect(list, hasLength(1));
      expect(list.first.value, 5740.7767);
    });

    test('tolerates the legacy ARRAY filtered_stats (bare call shape)', () {
      final json = {
        'city_id': 1,
        'name': 'Riyadh',
        'filtered_stats': [
          {'unit_type_id': 1, 'price_of_meter': 3782.11, 'median': 1},
          {'unit_type_id': 2, 'price_of_meter': 4909.05, 'median': 2},
        ],
      };

      final apartment = CityMarketStatModel.cityFromJson(
        json,
        query: buyApartment,
      );
      final villa = CityMarketStatModel.cityFromJson(
        json,
        query: const MarketQuery(unitTypeId: MarketUnitTypes.villa),
      );

      expect(apartment?.value, 3782.11);
      expect(villa?.value, 4909.05);
    });

    test('drops cities without data for the requested combination', () {
      final envelope = {
        'success': true,
        'data': [
          {'city_id': 20, 'name': 'Hafar Al Batin', 'filtered_stats': null},
        ],
      };

      expect(
        CityMarketStatModel.listFromEnvelope(envelope, query: buyApartment),
        isEmpty,
      );
    });

    test('parses districts (the map drill-down payload)', () {
      final envelope = {
        'success': true,
        'city_id': 1,
        'data': [
          {
            'district_id': 21,
            'name': 'Al Murabba Dist.',
            'lat': 24.6579,
            'lng': 46.70564,
            'overall': {'avg_price_per_meter': 11140.29},
            'filtered_stats': {
              'unit_type_id': 1,
              'price_of_meter': 2329,
              'median': 7342.78,
            },
          },
        ],
      };

      final list = CityMarketStatModel.districtsFromEnvelope(
        envelope,
        query: buyApartment,
      );

      expect(list, hasLength(1));
      expect(list.first.districtId, 21);
      expect(list.first.value, 2329);
    });
  });
}
