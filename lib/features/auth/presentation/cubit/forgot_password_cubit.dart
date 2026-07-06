import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/api_result.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/usecases/forgot_password_usecases.dart';
import 'forgot_password_state.dart';

/// Drives the forgot-password wizard against the live API:
///   sendCode → /auth/send-otp (returns verification_token, starts the resend
///   countdown) → verify → /auth/verify → reset → /auth/reset-password.
/// The resend countdown is a real [Timer.periodic], not dead text.
class ForgotPasswordCubit extends Cubit<ForgotPasswordState> {
  final SendResetCode _sendCode;
  final VerifyResetCode _verifyCode;
  final ResetPassword _resetPassword;

  /// Matches the site's "Resend code in 60s" window.
  static const int _resendWindow = 60;

  Timer? _timer;

  ForgotPasswordCubit(this._sendCode, this._verifyCode, this._resetPassword)
    : super(const ForgotPasswordState());

  Future<void> sendCode(String email) async {
    emit(state.copyWith(busy: true, error: null, email: email.trim()));
    final result = await _sendCode(email: email.trim());
    if (isClosed) return;
    result.when(
      success: (token) {
        emit(
          state.copyWith(
            busy: false,
            step: FpStep.code,
            verificationToken: token,
          ),
        );
        _startCountdown();
      },
      error: (f) => emit(state.copyWith(busy: false, error: _message(f))),
    );
  }

  Future<void> resend() async {
    if (state.secondsLeft > 0 || state.busy) return;
    emit(state.copyWith(busy: true, error: null));
    final result = await _sendCode(email: state.email);
    if (isClosed) return;
    result.when(
      success: (token) {
        emit(state.copyWith(busy: false, verificationToken: token));
        _startCountdown();
      },
      error: (f) => emit(state.copyWith(busy: false, error: _message(f))),
    );
  }

  Future<void> verify(String otp) async {
    final token = state.verificationToken;
    if (token == null) return;
    emit(state.copyWith(busy: true, error: null));
    final result = await _verifyCode(verificationToken: token, otp: otp);
    if (isClosed) return;
    result.when(
      success: (_) {
        _timer?.cancel();
        emit(state.copyWith(busy: false, step: FpStep.password));
      },
      error: (f) => emit(state.copyWith(busy: false, error: _message(f))),
    );
  }

  Future<void> reset({
    required String newPassword,
    required String confirmPassword,
  }) async {
    final token = state.verificationToken;
    if (token == null) return;
    emit(state.copyWith(busy: true, error: null));
    final result = await _resetPassword(
      verificationToken: token,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );
    if (isClosed) return;
    result.when(
      success: (_) => emit(state.copyWith(busy: false, step: FpStep.done)),
      error: (f) => emit(state.copyWith(busy: false, error: _message(f))),
    );
  }

  /// "Change Email" — back to step 1, clearing token + countdown.
  void changeEmail() {
    _timer?.cancel();
    emit(const ForgotPasswordState());
  }

  void clearError() {
    if (state.error != null) emit(state.copyWith(error: null));
  }

  void _startCountdown() {
    _timer?.cancel();
    emit(state.copyWith(secondsLeft: _resendWindow));
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (state.secondsLeft <= 1) {
        t.cancel();
        emit(state.copyWith(secondsLeft: 0));
      } else {
        emit(state.copyWith(secondsLeft: state.secondsLeft - 1));
      }
    });
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }

  String _message(Failure failure) => switch (failure) {
    NetworkFailure() => 'No internet connection.',
    UnauthorizedFailure() => 'Invalid or expired code. Please try again.',
    ValidationFailure(:final message) => message,
    ServerFailure() => 'Server error. Please try again later.',
    _ => 'Something went wrong. Please try again.',
  };
}
