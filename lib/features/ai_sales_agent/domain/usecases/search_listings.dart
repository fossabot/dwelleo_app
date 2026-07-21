import '../../../../core/config/app_config.dart';
import '../../../../core/errors/api_result.dart';
import '../entities/listing_result.dart';
import '../repositories/listing_search_repository.dart';

class SearchListings {
  final ListingSearchRepository _repository;
  const SearchListings(this._repository);

  static bool get isConfigured => AppConfig.serperApiKey.isNotEmpty;

  Future<ApiResult<List<ListingResult>>> call(
    String query, {
    String hl = 'ar',
  }) => _repository.search(query, hl: hl);
}
