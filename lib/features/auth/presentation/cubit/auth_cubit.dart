import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/api_result.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/session/session_state.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/usecases/login.dart';
import '../../domain/usecases/register.dart';
import '../../domain/usecases/verify_otp.dart';
import 'auth_state.dart';

/// Drives login, registration and OTP verification. Login persists the tokens
/// via [SecureStorage] and emits [AuthSuccess]; register emits [AuthRegistered]
/// (OTP sent → verify screen); OTP verify emits [AuthOtpVerified] (→ Login).
class AuthCubit extends Cubit<AuthState> {
  final Login _login;
  final Register _register;
  final VerifyOtp _verifyOtp;
  final ResendOtp _resendOtp;
  final SecureStorage _storage;
  final SessionState _session;

  AuthCubit(
    this._login,
    this._register,
    this._verifyOtp,
    this._resendOtp,
    this._storage,
    this._session,
  ) : super(const AuthIdle());

  Future<void> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    emit(const AuthLoading());
    final result = await _login(email: email, password: password);
    if (isClosed) return;
    await result.when(
      success: (session) async {
        await _persist(session);
        await _storage.setRememberMe(rememberMe);
        _session.isLoggedIn = true;
        emit(AuthSuccess(session));
      },
      error: (failure) async => emit(AuthFailure(_message(failure))),
    );
  }

  Future<void> register(
    Map<String, dynamic> payload, {
    required String email,
  }) async {
    emit(const AuthLoading());
    final result = await _register(payload);
    if (isClosed) return;
    result.when(
      success: (_) => emit(AuthRegistered(email)),
      error: (failure) => emit(AuthFailure(_message(failure))),
    );
  }

  Future<void> verifyOtp({required String email, required String code}) async {
    emit(const AuthLoading());
    final result = await _verifyOtp(email: email, code: code);
    if (isClosed) return;
    result.when(
      success: (_) => emit(const AuthOtpVerified()),
      error: (failure) => emit(AuthFailure(_message(failure))),
    );
  }

  Future<void> resendOtp({required String email}) async {
    final result = await _resendOtp(email: email);
    if (isClosed) return;
    result.when(
      success: (_) => emit(const AuthNotice('Verification code resent.')),
      error: (failure) => emit(AuthFailure(_message(failure))),
    );
  }

  Future<void> _persist(AuthSession session) async {
    await _storage.setAccessToken(session.accessToken);
    final refresh = session.refreshToken;
    if (refresh != null) await _storage.setRefreshToken(refresh);
  }

  String _message(Failure failure) => switch (failure) {
    NetworkFailure() => 'No internet connection.',
    UnauthorizedFailure() => 'Incorrect email or password.',
    ValidationFailure(:final message) => message,
    ServerFailure() => 'Server error. Please try again later.',
    _ => 'Something went wrong. Please try again.',
  };
}
