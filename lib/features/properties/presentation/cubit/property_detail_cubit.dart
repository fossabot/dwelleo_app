import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/api_result.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/usecases/get_property_detail.dart';
import 'property_detail_state.dart';

class PropertyDetailCubit extends Cubit<PropertyDetailState> {
  final GetPropertyDetail _getPropertyDetail;

  PropertyDetailCubit(this._getPropertyDetail)
    : super(const PropertyDetailInitial());

  Future<void> load(String slug) async {
    emit(const PropertyDetailLoading());
    final result = await _getPropertyDetail(slug);
    result.when(
      success: (data) => emit(PropertyDetailLoaded(data)),
      error: (failure) => emit(PropertyDetailError(_message(failure))),
    );
  }

  String _message(Failure failure) => switch (failure) {
    NetworkFailure() => 'No internet connection.',
    NotFoundFailure() => 'This property is no longer available.',
    ServerFailure() => 'Server error. Please try again later.',
    _ => 'Something went wrong. Please try again.',
  };
}
