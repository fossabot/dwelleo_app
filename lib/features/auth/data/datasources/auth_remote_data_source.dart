import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../domain/entities/auth_session.dart';

/// Talks to the real Dwelleo auth API (api.dwelleo.sa). Throws [DioException] on
/// transport/HTTP errors; the repository maps those into typed Failures.
///
/// Auth shares the website's backend, so an account created on dwelleo.sa logs
/// into the app (and vice-versa). Login is CONFIRMED: POST /auth/login
/// {email, password} → standard envelope {message, data:{...}}. The token field
/// name inside `data` varies by Laravel setup, so [_extractToken] checks the
/// common keys (token / access_token / accessToken, top-level or under data).
abstract interface class AuthRemoteDataSource {
  Future<AuthSession> login({required String email, required String password});

  /// Register creates the account and triggers an OTP; it does NOT return a
  /// login token (the user verifies the OTP, then logs in). Throws on 4xx/5xx.
  Future<void> register(Map<String, dynamic> payload);

  /// PENDING exact path/keys (HANDOFF §1). Verifies the sign-up OTP.
  Future<void> verifyOtp({required String email, required String code});

  /// PENDING exact path/keys. Re-sends the sign-up OTP.
  Future<void> resendOtp({required String email});

  // ---- Forgot password (VERIFIED live) -------------------------------------
  /// Sends a 4-digit reset code to [email]; returns the `verification_token`
  /// the next two steps must echo back. POST /auth/send-otp
  /// {email, type:"forgot_password"}. Rate-limited by the server.
  Future<String> sendResetCode({required String email});

  /// Verifies the reset [otp] against the [verificationToken] from [sendResetCode].
  /// POST /auth/verify {verification_token, otp}.
  Future<void> verifyResetCode({
    required String verificationToken,
    required String otp,
  });

  /// Sets a new password after the code is verified. POST /auth/reset-password
  /// {verification_token, new_password, new_password_confirmation}.
  Future<void> resetPassword({
    required String verificationToken,
    required String newPassword,
    required String confirmPassword,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio _dio;

  const AuthRemoteDataSourceImpl(this._dio);

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final res = await _dio.post<dynamic>(
      ApiEndpoints.login,
      data: {'email': email, 'password': password},
    );
    return _sessionFrom(res);
  }

  @override
  Future<void> register(Map<String, dynamic> payload) async {
    // Register issues an OTP; no token is returned, so we don't parse a session.
    // A 2xx means the account was created and the OTP was sent.
    await _dio.post<dynamic>(ApiEndpoints.register, data: payload);
  }

  @override
  Future<void> verifyOtp({required String email, required String code}) async {
    // PENDING: confirm path + body keys ({email, code} vs {phone, otp}) from a
    // live capture (HANDOFF §1 ACTION) before relying on this in production.
    await _dio.post<dynamic>(
      ApiEndpoints.verifyOtp,
      data: {'email': email, 'code': code},
    );
  }

  @override
  Future<void> resendOtp({required String email}) async {
    // PENDING: confirm path + body keys from a live capture.
    await _dio.post<dynamic>(ApiEndpoints.resendOtp, data: {'email': email});
  }

  @override
  Future<String> sendResetCode({required String email}) async {
    final res = await _dio.post<dynamic>(
      ApiEndpoints.sendOtp,
      // Exact value the website sends (captured live): "reset-password" (hyphen,
      // NOT "reset_password"/"forgot_password" — the server rejects those).
      data: {'email': email, 'type': 'reset-password'},
    );
    final token = _extractVerificationToken(res.data);
    if (token == null || token.isEmpty) {
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        type: DioExceptionType.badResponse,
        error: 'send-otp succeeded but no verification_token was returned.',
      );
    }
    return token;
  }

  @override
  Future<void> verifyResetCode({
    required String verificationToken,
    required String otp,
  }) async {
    await _dio.post<dynamic>(
      ApiEndpoints.verify,
      data: {'verification_token': verificationToken, 'otp': otp},
    );
  }

  @override
  Future<void> resetPassword({
    required String verificationToken,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await _dio.post<dynamic>(
      ApiEndpoints.resetPassword,
      data: {
        'verification_token': verificationToken,
        'new_password': newPassword,
        'new_password_confirmation': confirmPassword,
      },
    );
  }

  /// Pulls the `verification_token` from a send-otp response (top-level or under
  /// `data`, tolerating a couple of key spellings).
  static String? _extractVerificationToken(dynamic body) {
    final m = body is Map ? body : const {};
    final data = m['data'] is Map ? m['data'] as Map : const {};
    for (final v in [
      m['verification_token'],
      m['verificationToken'],
      data['verification_token'],
      data['verificationToken'],
      data['token'],
    ]) {
      if (v is String && v.isNotEmpty) return v;
    }
    return null;
  }

  /// Builds an [AuthSession] from a 2xx auth response, tolerating the different
  /// token field names a Laravel backend may use.
  AuthSession _sessionFrom(Response<dynamic> res) {
    final token = _extractToken(res.data);
    if (token == null || token.isEmpty) {
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        type: DioExceptionType.badResponse,
        error: 'Auth succeeded but no token field was found in the response.',
      );
    }
    return AuthSession(
      accessToken: token,
      refreshToken: _extractRefresh(res.data),
    );
  }

  static String? _extractToken(dynamic body) {
    final m = body is Map ? body : const {};
    final data = m['data'] is Map ? m['data'] as Map : const {};
    final nested = data['data'] is Map ? data['data'] as Map : const {};
    final tokenObj = data['token'] is Map ? data['token'] as Map : const {};
    for (final v in [
      m['token'],
      m['access_token'],
      m['accessToken'],
      data['token'],
      data['access_token'],
      data['accessToken'],
      tokenObj['access_token'], // {data:{token:{access_token:..}}}
      nested['token'],
      nested['access_token'],
    ]) {
      if (v is String && v.isNotEmpty) return v;
    }
    return null;
  }

  static String? _extractRefresh(dynamic body) {
    final m = body is Map ? body : const {};
    final data = m['data'] is Map ? m['data'] as Map : const {};
    for (final v in [
      m['refresh_token'],
      m['refreshToken'],
      data['refresh_token'],
      data['refreshToken'],
    ]) {
      if (v is String && v.isNotEmpty) return v;
    }
    return null;
  }
}
