import '../../../../core/errors/api_result.dart';
import '../repositories/auth_repository.dart';

/// Verifies the 4-digit sign-up OTP for [email].
class VerifyOtp {
  final AuthRepository _repository;

  const VerifyOtp(this._repository);

  Future<ApiResult<void>> call({required String email, required String code}) {
    return _repository.verifyOtp(email: email, code: code);
  }
}

/// Re-sends the sign-up OTP for [email].
class ResendOtp {
  final AuthRepository _repository;

  const ResendOtp(this._repository);

  Future<ApiResult<void>> call({required String email}) {
    return _repository.resendOtp(email: email);
  }
}
