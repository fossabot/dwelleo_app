import '../../../../core/errors/api_result.dart';
import '../repositories/auth_repository.dart';

/// Account registration. [payload] is the verified `/auth/register` body,
/// assembled from the sign-up form per the selected role. On success the
/// backend issues an OTP (no session), so this returns no data.
class Register {
  final AuthRepository _repository;

  const Register(this._repository);

  Future<ApiResult<void>> call(Map<String, dynamic> payload) {
    return _repository.register(payload);
  }
}
