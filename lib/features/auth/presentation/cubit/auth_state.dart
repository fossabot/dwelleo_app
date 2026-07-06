import '../../domain/entities/auth_session.dart';

sealed class AuthState {
  const AuthState();
}

class AuthIdle extends AuthState {
  const AuthIdle();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Login succeeded (session persisted) — navigate into the app.
class AuthSuccess extends AuthState {
  final AuthSession session;
  const AuthSuccess(this.session);
}

/// Register succeeded — the backend sent an OTP; go to the verification screen.
class AuthRegistered extends AuthState {
  final String email;
  const AuthRegistered(this.email);
}

/// OTP verified — the account is confirmed; go to Login.
class AuthOtpVerified extends AuthState {
  const AuthOtpVerified();
}

/// A non-blocking notice (e.g. "OTP resent") to surface without leaving the screen.
class AuthNotice extends AuthState {
  final String message;
  const AuthNotice(this.message);
}

class AuthFailure extends AuthState {
  final String message;
  const AuthFailure(this.message);
}
