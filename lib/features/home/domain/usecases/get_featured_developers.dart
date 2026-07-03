import '../../../../core/errors/api_result.dart';
import '../entities/developer.dart';
import '../repositories/home_repository.dart';

/// Developers for the "Featured Developers" rail. Business rule (mirrors the
/// website): only those the backend flags `featuredInHome`; if the flag comes
/// back empty, degrade gracefully to the full first page rather than an
/// empty-looking section.
class GetFeaturedDevelopers {
  final HomeRepository _repository;

  const GetFeaturedDevelopers(this._repository);

  Future<ApiResult<List<Developer>>> call() async {
    final result = await _repository.getDevelopers();
    return result.when(
      success: (all) {
        final featured = all
            .where((d) => d.featuredInHome)
            .toList(growable: false);
        return ApiSuccess(featured.isEmpty ? all : featured);
      },
      error: ApiError.new,
    );
  }
}
