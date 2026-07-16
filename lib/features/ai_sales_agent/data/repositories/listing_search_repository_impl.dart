import 'package:dio/dio.dart';

import '../../../../core/errors/api_result.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/entities/listing_result.dart';
import '../../domain/repositories/listing_search_repository.dart';
import '../datasources/serper_search_data_source.dart';

class ListingSearchRepositoryImpl implements ListingSearchRepository {
  final SerperSearchDataSource _dataSource;
  const ListingSearchRepositoryImpl(this._dataSource);

  @override
  Future<ApiResult<List<ListingResult>>> search(String query) async {
    try {
      final results = await _dataSource.search(query);
      return ApiSuccess(results);
    } on DioException catch (e) {
      return ApiError(
        ServerFailure(
          e.message ?? 'Listing search failed',
          statusCode: e.response?.statusCode,
        ),
      );
    } catch (e) {
      return ApiError(UnknownFailure(e.toString()));
    }
  }
}
