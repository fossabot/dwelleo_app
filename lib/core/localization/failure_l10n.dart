import '../../l10n/app_localizations.dart';
import '../errors/failure.dart';

/// Maps typed data-layer [Failure]s to user-facing localized messages.
/// Presentation-layer concern (uses AppLocalizations), shared by all features
/// whose states carry a [Failure].
extension FailureL10n on Failure {
  String localized(AppLocalizations l10n) => switch (this) {
    NetworkFailure() => l10n.errorNetwork,
    UnauthorizedFailure() => l10n.errorUnauthorized,
    NotFoundFailure() => l10n.noResults,
    ServerFailure() ||
    ValidationFailure() ||
    CacheFailure() ||
    UnknownFailure() => l10n.errorGeneric,
  };
}
