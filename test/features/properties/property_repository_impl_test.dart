import 'package:dio/dio.dart';
import 'package:dwelleo_app/core/errors/api_result.dart';
import 'package:dwelleo_app/core/errors/failure.dart';
import 'package:dwelleo_app/features/properties/data/datasources/property_remote_data_source.dart';
import 'package:dwelleo_app/features/properties/data/repositories/property_repository_impl.dart';
import 'package:dwelleo_app/features/properties/domain/entities/page_info.dart';
import 'package:dwelleo_app/features/properties/domain/entities/property.dart';
import 'package:dwelleo_app/features/properties/domain/entities/property_page.dart';
import 'package:dwelleo_app/features/properties/domain/entities/property_query.dart';
import 'package:flutter_test/flutter_test.dart';

class _SuccessSource implements PropertyRemoteDataSource {
  @override
  Future<List<Property>> getProperties({PropertyQuery? query}) async => const [
    Property(id: 1, slug: 'a', title: 'A'),
  ];

  @override
  Future<PropertyPage> searchProperties(PropertyQuery query) async =>
      const PropertyPage(
        properties: [Property(id: 1, slug: 'a', title: 'A')],
        pageInfo: PageInfo(
          total: 1912,
          count: 20,
          perPage: 20,
          currentPage: 1,
          totalPages: 96,
        ),
      );

  @override
  Future<Property> getPropertyBySlug(String slug) async =>
      const Property(id: 1, slug: 'a', title: 'A');
}

class _ThrowingSource implements PropertyRemoteDataSource {
  final DioException error;
  _ThrowingSource(this.error);

  @override
  Future<List<Property>> getProperties({PropertyQuery? query}) async =>
      throw error;

  @override
  Future<PropertyPage> searchProperties(PropertyQuery query) async =>
      throw error;

  @override
  Future<Property> getPropertyBySlug(String slug) async => throw error;
}

DioException _dio(DioExceptionType type, {int? status}) {
  final req = RequestOptions(path: '/api/v1/properties');
  return DioException(
    requestOptions: req,
    type: type,
    response: status == null
        ? null
        : Response(requestOptions: req, statusCode: status, data: const {}),
  );
}

void main() {
  group('PropertyRepositoryImpl', () {
    test('returns ApiSuccess with data on success', () async {
      final repo = PropertyRepositoryImpl(_SuccessSource());
      final result = await repo.getProperties();
      expect(result, isA<ApiSuccess<List<Property>>>());
      expect(result.dataOrNull, hasLength(1));
    });

    test('maps connectionError to NetworkFailure', () async {
      final repo = PropertyRepositoryImpl(
        _ThrowingSource(_dio(DioExceptionType.connectionError)),
      );
      final result = await repo.getProperties();
      expect(result, isA<ApiError<List<Property>>>());
      expect(result.failureOrNull, isA<NetworkFailure>());
    });

    test('maps 404 to NotFoundFailure', () async {
      final repo = PropertyRepositoryImpl(
        _ThrowingSource(_dio(DioExceptionType.badResponse, status: 404)),
      );
      final result = await repo.getPropertyBySlug('missing');
      expect(result.failureOrNull, isA<NotFoundFailure>());
    });

    test('maps 500 to ServerFailure', () async {
      final repo = PropertyRepositoryImpl(
        _ThrowingSource(_dio(DioExceptionType.badResponse, status: 500)),
      );
      final result = await repo.getProperties();
      expect(result.failureOrNull, isA<ServerFailure>());
    });
  });
}
