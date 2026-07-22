import 'package:dwelleo_app/features/market_insights/data/models/market_insight_model.dart';
import 'package:dwelleo_app/features/market_insights/domain/entities/market_insight.dart';
import 'package:flutter_test/flutter_test.dart';

/// Envelope copied VERBATIM from a live call (2026-07-21) so the parser is
/// pinned to the real contract, not to an assumption about it.
Map<String, dynamic> _envelope() => {
  'message': 'ok',
  'data': {
    'chart_type': 'top-cities-commercial-growth',
    'insight_type': 'rental',
    'name': 'Top 15 Cities - Commercial Contracts Growth',
    'description': 'Top 15 cities by total rental contracts…',
    'data': [
      {'city': 'Riyadh', 'commercial_2020': 10.3, 'commercial_2024': 15.37},
      {'city': 'Jeddah', 'commercial_2020': 7.57, 'commercial_2024': 12.79},
    ],
    'filters_applied': {},
  },
};

void main() {
  group('MarketInsightModel', () {
    test('parses rows, API-localized copy, and the year range', () {
      final series = MarketInsightModel.seriesFromEnvelope(
        _envelope(),
        MarketInsightChart.topCitiesCommercialGrowth,
      );

      expect(series.points, hasLength(2));
      expect(series.points.first.label, 'Riyadh');
      expect(series.points.first.base, 10.3);
      expect(series.points.first.latest, 15.37);
      // Titles come from the payload — never hardcoded in ARB.
      expect(series.name, 'Top 15 Cities - Commercial Contracts Growth');
      // Years are read out of the `*_<year>` keys, not hardcoded.
      expect(series.baseYear, 2020);
      expect(series.latestYear, 2024);
    });

    test('reads region rows too (third chart uses `region`, not `city`)', () {
      final json = _envelope();
      (json['data'] as Map)['data'] = [
        {
          'region': 'Madinah',
          'commercial_2020': 13.32,
          'commercial_2024': 19.66,
        },
      ];

      final series = MarketInsightModel.seriesFromEnvelope(
        json,
        MarketInsightChart.commercialUnitsGrowth,
      );

      expect(series.points.single.label, 'Madinah');
    });

    test('picks up a new year column without a code change', () {
      final json = _envelope();
      (json['data'] as Map)['data'] = [
        {'city': 'Riyadh', 'commercial_2019': 8.0, 'commercial_2025': 20.0},
      ];

      final series = MarketInsightModel.seriesFromEnvelope(
        json,
        MarketInsightChart.topCitiesCommercialGrowth,
      );

      expect(series.baseYear, 2019);
      expect(series.latestYear, 2025);
      expect(series.points.single.base, 8.0);
      expect(series.points.single.latest, 20.0);
    });

    test('a malformed payload yields an empty series, never a crash', () {
      final series = MarketInsightModel.seriesFromEnvelope({
        'data': 'not-a-map',
      }, MarketInsightChart.topCitiesCommercialGrowth);

      expect(series.points, isEmpty);
      expect(series.name, isEmpty);
    });

    test('parses lookups into filter options', () {
      final lookups = MarketInsightModel.lookupsFromEnvelope({
        'data': {
          'regions': [
            {'value': 'Al-Jawf', 'label': 'Al-Jawf'},
          ],
          'unit_types': [
            {'value': 'apartment', 'label': 'Apartment'},
          ],
          'years': [
            {'value': 2020, 'label': '2020'},
          ],
        },
      });

      expect(lookups.regions, ['Al-Jawf']);
      expect(lookups.unitTypes.single.value, 'apartment');
      expect(lookups.unitTypes.single.label, 'Apartment');
      expect(lookups.years, [2020]);
    });
  });

  group('growth maths (pinned to the website)', () {
    test('Riyadh 10.3 → 15.37 is the +49% the site prints', () {
      const point = MarketInsightPoint(
        label: 'Riyadh',
        base: 10.3,
        latest: 15.37,
      );

      expect((point.growth * 100).round(), 49);
      expect(point.multiplier, closeTo(1.49, 0.01));
    });

    test('overall growth is computed over totals, not averaged per row', () {
      final series = MarketInsightModel.seriesFromEnvelope(
        _envelope(),
        MarketInsightChart.topCitiesCommercialGrowth,
      );

      expect(series.baseTotal, closeTo(17.87, 0.001));
      expect(series.latestTotal, closeTo(28.16, 0.001));
      // (28.16 - 17.87) / 17.87 = 0.5758 — NOT the mean of 49% and 69%.
      expect(series.overallGrowth, closeTo(0.5758, 0.001));
    });

    test('a zero base cannot divide by zero', () {
      const point = MarketInsightPoint(label: 'X', base: 0, latest: 12);

      expect(point.growth, 0);
      expect(point.multiplier, 0);
    });
  });

  group('MarketInsightFilters', () {
    test('only sends the filters that are set', () {
      const filters = MarketInsightFilters(region: 'Al-Jawf', city: 'Abha');

      expect(filters.toQueryParams(), {'region': 'Al-Jawf', 'city': 'Abha'});
      expect(filters.activeCount, 2);
      expect(filters.isEmpty, isFalse);
    });

    test('copyWith can clear a value', () {
      const filters = MarketInsightFilters(region: 'Al-Jawf');

      final cleared = filters.copyWith(region: () => null);

      expect(cleared.isEmpty, isTrue);
      expect(cleared.toQueryParams(), isEmpty);
    });
  });

  group('chart paths match the live endpoints', () {
    test('each chart maps to its verified path segment', () {
      expect(
        MarketInsightChart.topCitiesCommercialGrowth.path,
        'top-cities-commercial-growth',
      );
      expect(
        MarketInsightChart.highestCommercialGrowthCities.path,
        'highest-commercial-growth-cities',
      );
      expect(
        MarketInsightChart.commercialUnitsGrowth.path,
        'commercial-units-growth',
      );
    });
  });
}
