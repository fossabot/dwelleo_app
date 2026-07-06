import 'package:dio/dio.dart';

import '../../../../core/errors/api_result.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

/// Catches data-layer exceptions at the boundary and maps them to typed Failures.
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remote;

  const AuthRepositoryImpl(this._remote);

  @override
  Future<ApiResult<AuthSession>> login({
    required String email,
    required String password,
  }) {
    return _guard(() => _remote.login(email: email, password: password));
  }

  @override
  Future<ApiResult<void>> register(Map<String, dynamic> payload) {
    return _guard(() => _remote.register(payload));
  }

  @override
  Future<ApiResult<void>> verifyOtp({
    required String email,
    required String code,
  }) {
    return _guard(() => _remote.verifyOtp(email: email, code: code));
  }

  @override
  Future<ApiResult<void>> resendOtp({required String email}) {
    return _guard(() => _remote.resendOtp(email: email));
  }

  @override
  Future<ApiResult<String>> sendResetCode({required String email}) {
    return _guard(() => _remote.sendResetCode(email: email));
  }

  @override
  Future<ApiResult<void>> verifyResetCode({
    required String verificationToken,
    required String otp,
  }) {
    return _guard(
      () => _remote.verifyResetCode(
        verificationToken: verificationToken,
        otp: otp,
      ),
    );
  }

  @override
  Future<ApiResult<void>> resetPassword({
    required String verificationToken,
    required String newPassword,
    required String confirmPassword,
  }) {
    return _guard(
      () => _remote.resetPassword(
        verificationToken: verificationToken,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      ),
    );
  }

  Future<ApiResult<T>> _guard<T>(Future<T> Function() request) async {
    try {
      return ApiSuccess(await request());
    } on DioException catch (e) {
      return DioClient.handleDioException<T>(e);
    } catch (e) {
      return ApiError(UnknownFailure(e.toString()));
    }
  }
}
