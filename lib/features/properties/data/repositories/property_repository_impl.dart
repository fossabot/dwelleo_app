import 'package:dio/dio.dart';

import '../../../../core/errors/api_result.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/property.dart';
import '../../domain/entities/property_page.dart';
import '../../domain/entities/property_query.dart';
import '../../domain/repositories/property_repository.dart';
import '../datasources/property_remote_data_source.dart';

/// Catches data-layer exceptions at the boundary and maps them to typed Failures.
class PropertyRepositoryImpl implements PropertyRepository {
  final PropertyRemoteDataSource _remote;

  const PropertyRepositoryImpl(this._remote);

  @override
  Future<ApiResult<List<Property>>> getProperties({PropertyQuery? query}) {
    return _guard(() => _remote.getProperties(query: query));
  }

  @override
  Future<ApiResult<PropertyPage>> searchProperties(PropertyQuery query) {
    return _guard(() => _remote.searchProperties(query));
  }

  @override
  Future<ApiResult<Property>> getPropertyBySlug(String slug) {
    return _guard(() => _remote.getPropertyBySlug(slug));
  }

  Future<ApiResult<T>> _guard<T>(Future<T> Function() request) async {
    try {
      return ApiSuccess(await request());
    } on DioException catch (e) {
      return DioClient.handleDioException<T>(e);
    } catch (e) {
      return ApiError(UnknownFailure(e.toString()));
    }
  }
}
