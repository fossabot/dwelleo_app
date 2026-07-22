import 'package:dwelleo_app/core/domain/entities/named_ref.dart';
import 'package:dwelleo_app/core/errors/api_result.dart';
import 'package:dwelleo_app/core/errors/failure.dart';
import 'package:dwelleo_app/features/home/domain/entities/city_market_stat.dart';
import 'package:dwelleo_app/features/home/domain/entities/developer.dart';
import 'package:dwelleo_app/features/home/domain/entities/project.dart';
import 'package:dwelleo_app/features/home/domain/repositories/home_repository.dart';
import 'package:dwelleo_app/features/home/domain/usecases/get_projects.dart';
import 'package:dwelleo_app/features/home/presentation/cubit/explore_cubit.dart';
import 'package:dwelleo_app/features/home/presentation/cubit/explore_state.dart';
import 'package:flutter_test/flutter_test.dart';

const _riyadh = NamedRef(id: 1, name: 'Riyadh');
const _jeddah = NamedRef(id: 11, name: 'Jeddah');

const _p1 = Project(id: 1, slug: 'a', name: 'A', city: _riyadh);
const _p2 = Project(id: 2, slug: 'b', name: 'B', city: _jeddah);
const _p3 = Project(id: 3, slug: 'c', name: 'C', city: _riyadh);

class _Repo implements HomeRepository {
  final ApiResult<List<Project>> projects;
  const _Repo(this.projects);

  @override
  Future<ApiResult<List<Project>>> getProjects() async => projects;

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

  @override
  Future<ApiResult<List<CityMarketStat>>> getCityMarketStats(
    MarketQuery query,
  ) async => const ApiSuccess([]);

  @override
  Future<ApiResult<List<MarketDistrict>>> getMarketDistricts(
    int cityId,
    MarketQuery query,
  ) async => const ApiSuccess([]);
}

void main() {
  group('ExploreCubit', () {
    test('load emits Loaded with all projects', () async {
      final cubit = ExploreCubit(
        GetProjects(const _Repo(ApiSuccess([_p1, _p2, _p3]))),
      );
      await cubit.load();

      final state = cubit.state;
      expect(state, isA<ExploreLoaded>());
      expect((state as ExploreLoaded).all, [_p1, _p2, _p3]);
      expect(state.selectedCity, isNull);
      await cubit.close();
    });

    test('cities are distinct, in first-seen order', () async {
      final cubit = ExploreCubit(
        GetProjects(const _Repo(ApiSuccess([_p1, _p2, _p3]))),
      );
      await cubit.load();

      expect((cubit.state as ExploreLoaded).cities, ['Riyadh', 'Jeddah']);
      await cubit.close();
    });

    test('selectCity filters; null resets to all', () async {
      final cubit = ExploreCubit(
        GetProjects(const _Repo(ApiSuccess([_p1, _p2, _p3]))),
      );
      await cubit.load();

      cubit.selectCity('Jeddah');
      expect((cubit.state as ExploreLoaded).filtered, [_p2]);

      cubit.selectCity(null);
      expect((cubit.state as ExploreLoaded).filtered, [_p1, _p2, _p3]);
      await cubit.close();
    });

    test('selectCity before load is a no-op', () {
      final cubit = ExploreCubit(GetProjects(const _Repo(ApiSuccess([_p1]))));
      cubit.selectCity('Riyadh');
      expect(cubit.state, isA<ExploreInitial>());
      cubit.close();
    });

    test('load failure emits ExploreError with the typed failure', () async {
      final cubit = ExploreCubit(
        GetProjects(const _Repo(ApiError(NetworkFailure()))),
      );
      await cubit.load();

      expect(cubit.state, isA<ExploreError>());
      expect((cubit.state as ExploreError).failure, isA<NetworkFailure>());
      await cubit.close();
    });
  });
}
