import 'package:flutter_bloc/flutter_bloc.dart';

// Provides the ApiResult.when extension used below.
import '../../../../core/errors/api_result.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/entities/project.dart';
import '../../domain/usecases/get_project_detail.dart';

sealed class ProjectDetailState {
  const ProjectDetailState();
}

/// Instant paint from the list item while the full payload loads.
class ProjectDetailLoading extends ProjectDetailState {
  final Project? preview;
  const ProjectDetailLoading([this.preview]);
}

class ProjectDetailLoaded extends ProjectDetailState {
  final Project project;
  const ProjectDetailLoaded(this.project);
}

class ProjectDetailError extends ProjectDetailState {
  final Failure failure;
  final Project? preview;
  const ProjectDetailError(this.failure, [this.preview]);
}

class ProjectDetailCubit extends Cubit<ProjectDetailState> {
  final GetProjectDetail _getProject;

  ProjectDetailCubit(this._getProject) : super(const ProjectDetailLoading());

  Future<void> load(int id, {Project? preview}) async {
    emit(ProjectDetailLoading(preview));
    final result = await _getProject(id);
    if (isClosed) return;
    result.when(
      success: (project) => emit(ProjectDetailLoaded(project)),
      error: (failure) => emit(ProjectDetailError(failure, preview)),
    );
  }
}
