import '../../../../core/errors/api_result.dart';
import '../repositories/auth_repository.dart';

/// Step 1 — send a reset code to the email; returns the `verification_token`.
class SendResetCode {
  final AuthRepository _repo;
  const SendResetCode(this._repo);

  Future<ApiResult<String>> call({required String email}) =>
      _repo.sendResetCode(email: email);
}

/// Step 2 — verify the reset code against the verification token.
class VerifyResetCode {
  final AuthRepository _repo;
  const VerifyResetCode(this._repo);

  Future<ApiResult<void>> call({
    required String verificationToken,
    required String otp,
  }) => _repo.verifyResetCode(verificationToken: verificationToken, otp: otp);
}

/// Step 3 — set the new password once the code is verified.
class ResetPassword {
  final AuthRepository _repo;
  const ResetPassword(this._repo);

  Future<ApiResult<void>> call({
    required String verificationToken,
    required String newPassword,
    required String confirmPassword,
  }) => _repo.resetPassword(
    verificationToken: verificationToken,
    newPassword: newPassword,
    confirmPassword: confirmPassword,
  );
}
