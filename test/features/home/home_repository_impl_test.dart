import 'package:dio/dio.dart';
import 'package:dwelleo_app/core/errors/api_result.dart';
import 'package:dwelleo_app/core/errors/failure.dart';
import 'package:dwelleo_app/features/home/data/datasources/home_remote_data_source.dart';
import 'package:dwelleo_app/features/home/data/repositories/home_repository_impl.dart';
import 'package:dwelleo_app/features/home/domain/entities/city_market_stat.dart';
import 'package:dwelleo_app/features/home/domain/entities/developer.dart';
import 'package:dwelleo_app/features/home/domain/entities/project.dart';
import 'package:flutter_test/flutter_test.dart';

const _query = MarketQuery();

class _SuccessSource implements HomeRemoteDataSource {
  @override
  Future<List<Developer>> getAgents() async => const [];
  @override
  Future<Project?> getProject(int id) async => null;

  @override
  Future<List<Project>> getProjects() async => const [
    Project(id: 1, slug: 'p', name: 'P'),
  ];

  @override
  Future<List<Developer>> getDevelopers() async => const [
    Developer(id: 1, name: 'D'),
  ];

  @override
  Future<List<Developer>> getBrokers() async => const [
    Developer(id: 2, name: 'B'),
  ];

  @override
  Future<List<CityMarketStat>> getCityMarketStats(MarketQuery query) async =>
      const [CityMarketStat(cityId: 1, name: 'Riyadh', value: 3782.11)];

  @override
  Future<List<MarketDistrict>> getMarketDistricts(
    int cityId,
    MarketQuery query,
  ) async => const [
    MarketDistrict(districtId: 21, name: 'Al Murabba', value: 2329),
  ];
}

class _ThrowingSource implements HomeRemoteDataSource {
  @override
  Future<List<Developer>> getAgents() async => throw error;
  @override
  Future<Project?> getProject(int id) async => throw error;

  final DioException error;
  _ThrowingSource(this.error);

  @override
  Future<List<Project>> getProjects() async => throw error;

  @override
  Future<List<Developer>> getDevelopers() async => throw error;

  @override
  Future<List<Developer>> getBrokers() async => throw error;

  @override
  Future<List<CityMarketStat>> getCityMarketStats(MarketQuery query) async =>
      throw error;

  @override
  Future<List<MarketDistrict>> getMarketDistricts(
    int cityId,
    MarketQuery query,
  ) async => throw error;
}

/// Counts underlying city-stat fetches so the in-flight dedup is observable.
class _CountingSource extends _SuccessSource {
  int cityStatsCalls = 0;

  @override
  Future<List<CityMarketStat>> getCityMarketStats(MarketQuery query) {
    cityStatsCalls++;
    return super.getCityMarketStats(query);
  }
}

DioException _dio(DioExceptionType type, {int? status}) {
  final req = RequestOptions(path: '/api/v1/projects');
  return DioException(
    requestOptions: req,
    type: type,
    response: status == null
        ? null
        : Response(requestOptions: req, statusCode: status, data: const {}),
  );
}

void main() {
  group('HomeRepositoryImpl', () {
    test('returns ApiSuccess for each feed on success', () async {
      final repo = HomeRepositoryImpl(_SuccessSource());

      expect((await repo.getProjects()).dataOrNull, hasLength(1));
      expect((await repo.getDevelopers()).dataOrNull, hasLength(1));
      expect((await repo.getBrokers()).dataOrNull, hasLength(1));
      expect((await repo.getCityMarketStats(_query)).dataOrNull, hasLength(1));
      expect(
        (await repo.getMarketDistricts(1, _query)).dataOrNull,
        hasLength(1),
      );
    });

    test('maps connectionError to NetworkFailure', () async {
      final repo = HomeRepositoryImpl(
        _ThrowingSource(_dio(DioExceptionType.connectionError)),
      );
      final result = await repo.getProjects();
      expect(result, isA<ApiError<List<Project>>>());
      expect(result.failureOrNull, isA<NetworkFailure>());
    });

    test('maps 401 to UnauthorizedFailure', () async {
      final repo = HomeRepositoryImpl(
        _ThrowingSource(_dio(DioExceptionType.badResponse, status: 401)),
      );
      final result = await repo.getBrokers();
      expect(result.failureOrNull, isA<UnauthorizedFailure>());
    });

    test('maps 500 to ServerFailure', () async {
      final repo = HomeRepositoryImpl(
        _ThrowingSource(_dio(DioExceptionType.badResponse, status: 500)),
      );
      final result = await repo.getCityMarketStats(_query);
      expect(result.failureOrNull, isA<ServerFailure>());
    });

    test('coalesces concurrent identical city-stat requests', () async {
      // The home Table and Map cubits load the same query on startup — one
      // network call must serve both instead of two identical GETs.
      final source = _CountingSource();
      final repo = HomeRepositoryImpl(source);

      final results = await Future.wait([
        repo.getCityMarketStats(_query),
        repo.getCityMarketStats(_query),
      ]);

      expect(source.cityStatsCalls, 1);
      expect(results[0].dataOrNull, hasLength(1));
      expect(results[1].dataOrNull, hasLength(1));
    });

    test(
      're-fetches city stats after the in-flight request completes',
      () async {
        // Dedup is in-flight only, so pull-to-refresh still hits the network.
        final source = _CountingSource();
        final repo = HomeRepositoryImpl(source);

        await repo.getCityMarketStats(_query);
        await repo.getCityMarketStats(_query);

        expect(source.cityStatsCalls, 2);
      },
    );
  });
}
