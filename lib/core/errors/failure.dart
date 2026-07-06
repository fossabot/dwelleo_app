sealed class Failure {
  final String message;
  const Failure(this.message);
}

final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection']);
}

final class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure(super.message, {this.statusCode});
}

final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([
    super.message = 'Session expired. Please log in again.',
  ]);
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Resource not found']);
}

final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

final class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Local data error']);
}

final class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'An unexpected error occurred']);
}
