import '../../../../core/errors/api_result.dart';
import '../entities/auth_session.dart';

/// Auth contract. Returns typed [ApiResult]; the data layer maps transport/HTTP
/// errors into Failures so the presentation layer never sees raw exceptions.
abstract interface class AuthRepository {
  Future<ApiResult<AuthSession>> login({
    required String email,
    required String password,
  });

  /// Registers the account and triggers an OTP; returns no session (the user
  /// verifies the OTP, then logs in). [payload] is the verified `/auth/register`
  /// body (HANDOFF §1).
  Future<ApiResult<void>> register(Map<String, dynamic> payload);

  /// Verifies the sign-up OTP for [email].
  Future<ApiResult<void>> verifyOtp({
    required String email,
    required String code,
  });

  /// Re-sends the sign-up OTP for [email].
  Future<ApiResult<void>> resendOtp({required String email});

  // ---- Forgot password -----------------------------------------------------
  /// Sends a reset code to [email]; returns the `verification_token`.
  Future<ApiResult<String>> sendResetCode({required String email});

  /// Verifies the reset [otp] against [verificationToken].
  Future<ApiResult<void>> verifyResetCode({
    required String verificationToken,
    required String otp,
  });

  /// Sets a new password after the reset code is verified.
  Future<ApiResult<void>> resetPassword({
    required String verificationToken,
    required String newPassword,
    required String confirmPassword,
  });
}
