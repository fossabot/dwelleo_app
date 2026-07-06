import 'failure.dart';

sealed class ApiResult<T> {
  const ApiResult();
}

final class ApiSuccess<T> extends ApiResult<T> {
  final T data;
  const ApiSuccess(this.data);
}

final class ApiError<T> extends ApiResult<T> {
  final Failure failure;
  const ApiError(this.failure);
}

extension ApiResultX<T> on ApiResult<T> {
  bool get isSuccess => this is ApiSuccess<T>;
  bool get isError => this is ApiError<T>;

  T? get dataOrNull => switch (this) {
    ApiSuccess(:final data) => data,
    ApiError() => null,
  };

  Failure? get failureOrNull => switch (this) {
    ApiSuccess() => null,
    ApiError(:final failure) => failure,
  };

  R when<R>({
    required R Function(T data) success,
    required R Function(Failure failure) error,
  }) => switch (this) {
    ApiSuccess(:final data) => success(data),
    ApiError(:final failure) => error(failure),
  };
}
