import '../../../../core/errors/api_result.dart';
import '../entities/developer.dart';
import '../repositories/home_repository.dart';

/// Brokerages for the "Featured Brokers" tab — same featured-in-home rule
/// as developers: prefer the backend's flag, degrade to the full first page.
class GetFeaturedBrokers {
  final HomeRepository _repository;

  const GetFeaturedBrokers(this._repository);

  Future<ApiResult<List<Developer>>> call() async {
    final result = await _repository.getBrokers();
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
