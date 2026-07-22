import '../../../../core/errors/api_result.dart';
import '../entities/developer.dart';
import '../repositories/home_repository.dart';

/// Agents list for the directory's third tab.
///
/// VERIFIED live 2026-07-21: `/developers?filter[user_type]=agent` returns a
/// distinct set (26 agents) from developers (59) and brokers (116) — the
/// same three tabs dwelleo.sa's Developers page shows.
class GetAllAgents {
  final HomeRepository _repository;

  const GetAllAgents(this._repository);

  Future<ApiResult<List<Developer>>> call() => _repository.getAgents();
}
