import 'package:dwelleo_app/core/errors/api_result.dart';
import 'package:dwelleo_app/core/errors/failure.dart';
import 'package:dwelleo_app/features/home/domain/entities/city_market_stat.dart';
import 'package:dwelleo_app/features/home/domain/entities/developer.dart';
import 'package:dwelleo_app/features/home/domain/entities/project.dart';
import 'package:dwelleo_app/features/home/domain/repositories/home_repository.dart';
import 'package:dwelleo_app/features/home/domain/usecases/get_city_market_stats.dart';
import 'package:dwelleo_app/features/home/presentation/cubit/home_state.dart';
import 'package:dwelleo_app/features/home/presentation/cubit/market_stats_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

const _riyadhBuy = CityMarketStat(cityId: 1, name: 'Riyadh', value: 3782.11);
const _makkahBuy = CityMarketStat(cityId: 10, name: 'Makkah', value: 4614.58);
const _riyadhRent = CityMarketStat(cityId: 1, name: 'Riyadh', value: 5836.32);

/// Serves buy/rent fixtures and counts calls (for the cache test).
class _Repo implements HomeRepository {
  int calls = 0;
  final bool fail;
  _Repo({this.fail = false});

  @override
  Future<ApiResult<List<CityMarketStat>>> getCityMarketStats(
    MarketQuery query,
  ) async {
    calls++;
    if (fail) return const ApiError(NetworkFailure());
    return ApiSuccess(
      query.transaction == MarketTransaction.rent
          ? const [_riyadhRent]
          : const [_riyadhBuy, _makkahBuy], // deliberately unsorted
    );
  }

  @override
  Future<ApiResult<List<MarketDistrict>>> getMarketDistricts(
    int cityId,
    MarketQuery query,
  ) async => const ApiSuccess([]);

  @override
  Future<ApiResult<List<Project>>> getProjects() async => const ApiSuccess([]);

  @override
  Future<ApiResult<Project>> getProject(int id) async =>
      const ApiError(UnknownFailure('unused in this test'));

  @override
  Future<ApiResult<List<Developer>>> getDevelopers() async =>
      const ApiSuccess([]);

  @override
  Future<ApiResult<List<Developer>>> getBrokers() async => const ApiSuccess([]);

  @override
  Future<ApiResult<List<Developer>>> getAgents() async => const ApiSuccess([]);
}

void main() {
  group('MarketStatsCubit', () {
    test('load() fetches apartment+buy and sorts priciest first', () async {
      final cubit = MarketStatsCubit(GetCityMarketStats(_Repo()));
      await cubit.load();

      final stats =
          (cubit.state.stats as SectionLoaded<List<CityMarketStat>>).data;
      expect(stats.first, _makkahBuy); // 4,614.58 leads, like the website
      expect(stats.last, _riyadhBuy);
      await cubit.close();
    });

    test('setTransaction(rent) refetches with the rent params', () async {
      final cubit = MarketStatsCubit(GetCityMarketStats(_Repo()));
      await cubit.load();
      await cubit.setTransaction(MarketTransaction.rent);

      expect(cubit.state.query.transaction, MarketTransaction.rent);
      expect((cubit.state.stats as SectionLoaded<List<CityMarketStat>>).data, [
        _riyadhRent,
      ]);
      await cubit.close();
    });

    test('toggling back to a fetched combination hits the cache', () async {
      final repo = _Repo();
      final cubit = MarketStatsCubit(GetCityMarketStats(repo));
      await cubit.load(); // 1
      await cubit.setTransaction(MarketTransaction.rent); // 2
      await cubit.setTransaction(MarketTransaction.buy); // cached → still 2

      expect(repo.calls, 2);
      expect(
        (cubit.state.stats as SectionLoaded<List<CityMarketStat>>).data.first,
        _makkahBuy,
      );
      await cubit.close();
    });

    test('failure lands in SectionError with the typed failure', () async {
      final cubit = MarketStatsCubit(GetCityMarketStats(_Repo(fail: true)));
      await cubit.load();

      expect(
        (cubit.state.stats as SectionError<List<CityMarketStat>>).failure,
        isA<NetworkFailure>(),
      );
      await cubit.close();
    });
  });
}
