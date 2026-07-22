import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/api_result.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/entities/developer.dart';
import '../../domain/usecases/get_all_agents.dart';
import '../../domain/usecases/get_all_brokers.dart';
import '../../domain/usecases/get_all_developers.dart';

sealed class DirectoryState {
  const DirectoryState();
}

class DirectoryLoading extends DirectoryState {
  const DirectoryLoading();
}

class DirectoryLoaded extends DirectoryState {
  final List<Developer> developers;
  final List<Developer> brokers;
  final List<Developer> agents;

  const DirectoryLoaded(this.developers, this.brokers, this.agents);
}

class DirectoryError extends DirectoryState {
  final Failure failure;

  const DirectoryError(this.failure);
}

/// Loads both partner lists for the directory page (site parity: dwelleo.sa
/// has a Developers page with a search engine; brokers ride along as a tab).
class DevelopersDirectoryCubit extends Cubit<DirectoryState> {
  final GetAllDevelopers _getDevelopers;
  final GetAllBrokers _getBrokers;
  final GetAllAgents _getAgents;

  DevelopersDirectoryCubit(
    this._getDevelopers,
    this._getBrokers,
    this._getAgents,
  ) : super(const DirectoryLoading());

  Future<void> load() async {
    emit(const DirectoryLoading());
    final results = await Future.wait([
      _getDevelopers(),
      _getBrokers(),
      _getAgents(),
    ]);
    if (isClosed) return;

    var developers = const <Developer>[];
    var brokers = const <Developer>[];
    var agents = const <Developer>[];
    Failure? devFailure;
    Failure? brokerFailure;
    Failure? agentFailure;
    results[0].when(
      success: (list) => developers = list,
      error: (f) => devFailure = f,
    );
    results[1].when(
      success: (list) => brokers = list,
      error: (f) => brokerFailure = f,
    );
    results[2].when(
      success: (list) => agents = list,
      error: (f) => agentFailure = f,
    );

    // Show the page if ANY list arrived; error only when all three failed.
    final failure = devFailure;
    if (failure != null && brokerFailure != null && agentFailure != null) {
      emit(DirectoryError(failure));
      return;
    }
    emit(DirectoryLoaded(developers, brokers, agents));
  }
}
