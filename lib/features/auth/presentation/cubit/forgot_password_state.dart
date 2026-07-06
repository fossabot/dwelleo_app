/// The three steps of the forgot-password wizard (single route, swapped content
/// like dwelleo.sa/forget-password).
enum FpStep { email, code, password, done }

/// Immutable state for the forgot-password flow. One class (not a sealed union)
/// because the wizard carries data across steps (email, verification token,
/// resend countdown) and layers a transient busy/error on top of the current
/// step — a copyWith model expresses those transitions cleanly.
class ForgotPasswordState {
  final FpStep step;
  final String email;
  final String? verificationToken;

  /// Live resend countdown (seconds). 0 = resend available.
  final int secondsLeft;

  final bool busy;
  final String? error;

  const ForgotPasswordState({
    this.step = FpStep.email,
    this.email = '',
    this.verificationToken,
    this.secondsLeft = 0,
    this.busy = false,
    this.error,
  });

  static const Object _keep = Object();

  ForgotPasswordState copyWith({
    FpStep? step,
    String? email,
    Object? verificationToken = _keep,
    int? secondsLeft,
    bool? busy,
    Object? error = _keep,
  }) {
    return ForgotPasswordState(
      step: step ?? this.step,
      email: email ?? this.email,
      verificationToken: verificationToken == _keep
          ? this.verificationToken
          : verificationToken as String?,
      secondsLeft: secondsLeft ?? this.secondsLeft,
      busy: busy ?? this.busy,
      error: error == _keep ? this.error : error as String?,
    );
  }
}
