import '../../../../core/errors/api_result.dart';
import '../entities/listing_result.dart';

abstract class ListingSearchRepository {
  Future<ApiResult<List<ListingResult>>> search(String query);
}
