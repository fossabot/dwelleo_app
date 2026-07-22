import '../../../../core/errors/api_result.dart';
import '../entities/developer.dart';
import '../repositories/home_repository.dart';

/// Full brokerages list (first page) for the directory's Brokers tab.
class GetAllBrokers {
  final HomeRepository _repository;

  const GetAllBrokers(this._repository);

  Future<ApiResult<List<Developer>>> call() => _repository.getBrokers();
}
