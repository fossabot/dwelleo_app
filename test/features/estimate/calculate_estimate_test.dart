import 'package:dwelleo_app/core/errors/api_result.dart';
import 'package:dwelleo_app/core/errors/failure.dart';
import 'package:dwelleo_app/features/estimate/domain/entities/estimate_models.dart';
import 'package:dwelleo_app/features/estimate/domain/usecases/calculate_estimate.dart';
import 'package:dwelleo_app/features/home/domain/entities/city_market_stat.dart';
import 'package:dwelleo_app/features/home/domain/entities/developer.dart';
import 'package:dwelleo_app/features/home/domain/entities/project.dart';
import 'package:dwelleo_app/features/home/domain/repositories/home_repository.dart';
import 'package:dwelleo_app/features/home/domain/usecases/get_market_districts.dart';
import 'package:flutter_test/flutter_test.dart';

/// Repo double that answers /market/districts with fixed numbers so the
/// estimate maths can be asserted exactly.
class _Repo implements HomeRepository {
  static const num buyPerSqm = 7747;
  static const num rentMonthly = 2458;

  final bool failBuy;

  const _Repo({this.failBuy = false});

  @override
  Future<ApiResult<List<MarketDistrict>>> getMarketDistricts(
    int cityId,
    MarketQuery query,
  ) async {
    if (failBuy) return const ApiError(NetworkFailure());
    final value = query.transaction == MarketTransaction.buy
        ? buyPerSqm
        : rentMonthly;
    return ApiSuccess([
      MarketDistrict(districtId: 55, name: 'Al Amal Dist.', value: value),
      MarketDistrict(districtId: 99, name: 'Other', value: 1),
    ]);
  }

  @override
  Future<ApiResult<List<Project>>> getProjects() async => const ApiSuccess([]);

  @override
  Future<ApiResult<Project>> getProject(int id) async =>
      const ApiError(UnknownFailure('unused'));

  @override
  Future<ApiResult<List<Developer>>> getDevelopers() async =>
      const ApiSuccess([]);

  @override
  Future<ApiResult<List<Developer>>> getBrokers() async => const ApiSuccess([]);

  @override
  Future<ApiResult<List<Developer>>> getAgents() async => const ApiSuccess([]);

  @override
  Future<ApiResult<List<CityMarketStat>>> getCityMarketStats(
    MarketQuery query,
  ) async => const ApiSuccess([]);
}

const _input = EstimateInput(
  cityId: 1,
  cityName: 'Riyadh',
  districtId: 55,
  districtName: 'Al Amal Dist.',
  areaSqm: 180,
  bedrooms: 2,
);

void main() {
  group('CalculateEstimate', () {
    test(
      'mid is area x district price per m² (site-verified sample)',
      () async {
        final useCase = CalculateEstimate(GetMarketDistricts(const _Repo()));

        final result = await useCase(_input);

        final value = (result as ApiSuccess<EstimateResult>).data;
        expect(value.mid, 180 * 7747);
        expect(value.pricePerSqm, 7747);
      },
    );

    test('low/high use the exact 0.91 / 1.07 spread', () async {
      final useCase = CalculateEstimate(GetMarketDistricts(const _Repo()));

      final value = (await useCase(_input) as ApiSuccess<EstimateResult>).data;

      expect(value.low, closeTo(value.mid * 0.91, 0.001));
      expect(value.high, closeTo(value.mid * 1.07, 0.001));
    });

    test(
      'annual rent is monthly x 12 and yield divides by the sale price',
      () async {
        final useCase = CalculateEstimate(GetMarketDistricts(const _Repo()));

        final value =
            (await useCase(_input) as ApiSuccess<EstimateResult>).data;

        expect(value.annualRent, 2458 * 12);
        expect(value.netYield, closeTo((2458 * 12) / (180 * 7747), 0.0001));
      },
    );

    test('renting makes the annual rent the headline figure', () async {
      final useCase = CalculateEstimate(GetMarketDistricts(const _Repo()));

      final value =
          (await useCase(_input.copyWith(purpose: EstimatePurpose.rent))
                  as ApiSuccess<EstimateResult>)
              .data;

      expect(value.mid, 2458 * 12);
      // No per-m² figure exists on the rent side of the API.
      expect(value.pricePerSqm, isNull);
    });

    test(
      'missing location or area is rejected before any network call',
      () async {
        final useCase = CalculateEstimate(GetMarketDistricts(const _Repo()));

        final result = await useCase(const EstimateInput());

        expect(result, isA<ApiError<EstimateResult>>());
      },
    );

    test('an unknown district reports no data rather than guessing', () async {
      final useCase = CalculateEstimate(GetMarketDistricts(const _Repo()));

      final result = await useCase(_input.copyWith(districtId: () => 4321));

      expect(result, isA<ApiError<EstimateResult>>());
    });

    test('a failed market call surfaces the failure', () async {
      final useCase = CalculateEstimate(
        GetMarketDistricts(const _Repo(failBuy: true)),
      );

      final result = await useCase(_input);

      expect(result, isA<ApiError<EstimateResult>>());
    });

    test('confidence rises as optional characteristics are added', () async {
      const base = _input;
      final withYear = base.copyWith(yearBuilt: () => 2015);
      final withBoost = withYear.copyWith(balcony: true);

      expect(base.confidence, 3);
      expect(withYear.confidence, 4);
      expect(withBoost.confidence, 5);
    });
  });
}
