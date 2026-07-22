import 'package:dwelleo_app/core/errors/api_result.dart';
import 'package:dwelleo_app/core/errors/failure.dart';
import 'package:dwelleo_app/features/home/domain/entities/city_market_stat.dart';
import 'package:dwelleo_app/features/home/domain/entities/developer.dart';
import 'package:dwelleo_app/features/home/domain/entities/project.dart';
import 'package:dwelleo_app/features/home/domain/repositories/home_repository.dart';
import 'package:dwelleo_app/features/home/domain/usecases/get_featured_brokers.dart';
import 'package:dwelleo_app/features/home/domain/usecases/get_featured_developers.dart';
import 'package:dwelleo_app/features/home/domain/usecases/get_projects.dart';
import 'package:dwelleo_app/features/home/presentation/cubit/home_cubit.dart';
import 'package:dwelleo_app/features/home/presentation/cubit/home_state.dart';
import 'package:dwelleo_app/features/properties/domain/entities/property.dart';
import 'package:dwelleo_app/features/properties/domain/entities/property_page.dart';
import 'package:dwelleo_app/features/properties/domain/entities/property_query.dart';
import 'package:dwelleo_app/features/properties/domain/repositories/property_repository.dart';
import 'package:dwelleo_app/features/properties/domain/usecases/get_properties.dart';
import 'package:flutter_test/flutter_test.dart';

const _project = Project(id: 1, slug: 'p', name: 'P');
const _developer = Developer(id: 1, name: 'D', featuredInHome: true);
const _broker = Developer(id: 2, name: 'B', featuredInHome: true);
const _property = Property(id: 1, slug: 'a', title: 'A');

class _FakeHomeRepo implements HomeRepository {
  final ApiResult<List<Project>> projects;
  final ApiResult<List<Developer>> developers;
  final ApiResult<List<Developer>> brokers;

  const _FakeHomeRepo({
    this.projects = const ApiSuccess([_project]),
    this.developers = const ApiSuccess([_developer]),
    this.brokers = const ApiSuccess([_broker]),
  });

  @override
  Future<ApiResult<List<Project>>> getProjects() async => projects;

  @override
  Future<ApiResult<Project>> getProject(int id) async =>
      const ApiError(UnknownFailure('unused in this test'));

  @override
  Future<ApiResult<List<Developer>>> getDevelopers() async => developers;

  @override
  Future<ApiResult<List<Developer>>> getBrokers() async => brokers;

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

class _FakePropertyRepo implements PropertyRepository {
  final ApiResult<List<Property>> result;

  const _FakePropertyRepo([this.result = const ApiSuccess([_property])]);

  @override
  Future<ApiResult<List<Property>>> getProperties({
    PropertyQuery? query,
  }) async => result;

  @override
  Future<ApiResult<PropertyPage>> searchProperties(PropertyQuery query) async =>
      result.when(
        success: (items) => ApiSuccess(PropertyPage(properties: items)),
        error: ApiError.new,
      );

  @override
  Future<ApiResult<Property>> getPropertyBySlug(String slug) async =>
      const ApiSuccess(_property);
}

HomeCubit _cubit({
  _FakeHomeRepo home = const _FakeHomeRepo(),
  _FakePropertyRepo properties = const _FakePropertyRepo(),
}) {
  return HomeCubit(
    GetProperties(properties),
    GetProjects(home),
    GetFeaturedDevelopers(home),
    GetFeaturedBrokers(home),
  );
}

void main() {
  group('HomeCubit', () {
    test('starts with every section loading', () {
      final cubit = _cubit();
      expect(cubit.state.featured, isA<SectionLoading<List<Property>>>());
      expect(cubit.state.projects, isA<SectionLoading<List<Project>>>());
      expect(cubit.state.developers, isA<SectionLoading<List<Developer>>>());
      expect(cubit.state.brokers, isA<SectionLoading<List<Developer>>>());
      cubit.close();
    });

    test('load() resolves all four sections on success', () async {
      final cubit = _cubit();
      await cubit.load();

      expect((cubit.state.featured as SectionLoaded<List<Property>>).data, [
        _property,
      ]);
      expect((cubit.state.projects as SectionLoaded<List<Project>>).data, [
        _project,
      ]);
      expect((cubit.state.developers as SectionLoaded<List<Developer>>).data, [
        _developer,
      ]);
      expect((cubit.state.brokers as SectionLoaded<List<Developer>>).data, [
        _broker,
      ]);
      await cubit.close();
    });

    test('one failing feed errors ONLY its own section', () async {
      final cubit = _cubit(
        home: const _FakeHomeRepo(brokers: ApiError(NetworkFailure())),
      );
      await cubit.load();

      expect(cubit.state.brokers, isA<SectionError<List<Developer>>>());
      // The rest of the home stays alive.
      expect(cubit.state.featured, isA<SectionLoaded<List<Property>>>());
      expect(cubit.state.projects, isA<SectionLoaded<List<Project>>>());
      expect(cubit.state.developers, isA<SectionLoaded<List<Developer>>>());
      await cubit.close();
    });

    test('featured and projects can fail while the rest stays alive', () async {
      final cubit = _cubit(
        home: const _FakeHomeRepo(
          projects: ApiError(ServerFailure('boom', statusCode: 500)),
        ),
        properties: const _FakePropertyRepo(ApiError(NetworkFailure())),
      );
      await cubit.load();

      expect(cubit.state.featured, isA<SectionError<List<Property>>>());
      expect(cubit.state.projects, isA<SectionError<List<Project>>>());
      expect(cubit.state.developers, isA<SectionLoaded<List<Developer>>>());
      expect(cubit.state.brokers, isA<SectionLoaded<List<Developer>>>());
      await cubit.close();
    });
  });

  group('GetFeaturedDevelopers', () {
    test('keeps only featuredInHome developers', () async {
      const flagged = Developer(id: 1, name: 'A', featuredInHome: true);
      const other = Developer(id: 2, name: 'B');
      const repo = _FakeHomeRepo(developers: ApiSuccess([flagged, other]));

      final result = await GetFeaturedDevelopers(repo)();

      expect(result.dataOrNull, [flagged]);
    });

    test('falls back to the full list when nothing is flagged', () async {
      const a = Developer(id: 1, name: 'A');
      const b = Developer(id: 2, name: 'B');
      const repo = _FakeHomeRepo(developers: ApiSuccess([a, b]));

      final result = await GetFeaturedDevelopers(repo)();

      expect(result.dataOrNull, [a, b]);
    });
  });

  group('GetFeaturedBrokers', () {
    test('keeps only featuredInHome brokers', () async {
      const flagged = Developer(id: 1, name: 'A', featuredInHome: true);
      const other = Developer(id: 2, name: 'B');
      const repo = _FakeHomeRepo(brokers: ApiSuccess([flagged, other]));

      final result = await GetFeaturedBrokers(repo)();

      expect(result.dataOrNull, [flagged]);
    });

    test('propagates failures unchanged', () async {
      const repo = _FakeHomeRepo(
        brokers: ApiError(ServerFailure('boom', statusCode: 500)),
      );

      final result = await GetFeaturedBrokers(repo)();

      expect(result.failureOrNull, isA<ServerFailure>());
    });
  });
}
