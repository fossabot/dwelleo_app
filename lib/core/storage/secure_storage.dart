import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

class SecureStorage {
  SecureStorage(this._storage);

  final FlutterSecureStorage _storage;

  static const _androidOptions = AndroidOptions.defaultOptions;
  static const _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  );

  Future<void> setAccessToken(String token) => _storage.write(
    key: AppConstants.accessTokenKey,
    value: token,
    aOptions: _androidOptions,
    iOptions: _iosOptions,
  );

  Future<String?> getAccessToken() => _storage.read(
    key: AppConstants.accessTokenKey,
    aOptions: _androidOptions,
    iOptions: _iosOptions,
  );

  Future<void> setRefreshToken(String token) => _storage.write(
    key: AppConstants.refreshTokenKey,
    value: token,
    aOptions: _androidOptions,
    iOptions: _iosOptions,
  );

  Future<String?> getRefreshToken() => _storage.read(
    key: AppConstants.refreshTokenKey,
    aOptions: _androidOptions,
    iOptions: _iosOptions,
  );

  Future<void> setLocale(String locale) =>
      _storage.write(key: AppConstants.localeKey, value: locale);

  Future<String?> getLocale() => _storage.read(key: AppConstants.localeKey);

  /// Theme mode persisted as 'light' | 'dark' | 'system'.
  Future<void> setThemeMode(String mode) =>
      _storage.write(key: AppConstants.themeModeKey, value: mode);

  Future<String?> getThemeMode() =>
      _storage.read(key: AppConstants.themeModeKey);

  Future<void> setOnboardingDone() =>
      _storage.write(key: AppConstants.onboardingDoneKey, value: 'true');

  Future<bool> isOnboardingDone() async {
    final v = await _storage.read(key: AppConstants.onboardingDoneKey);
    return v == 'true';
  }

  /// Whether the last login asked to be remembered. When false, [bootstrap]
  /// clears the persisted token on the next cold start so login is required.
  Future<void> setRememberMe(bool value) =>
      _storage.write(key: AppConstants.rememberMeKey, value: value.toString());

  Future<bool> getRememberMe() async {
    final v = await _storage.read(key: AppConstants.rememberMeKey);
    return v == 'true';
  }

  Future<void> clearAuth() async {
    await _storage.delete(
      key: AppConstants.accessTokenKey,
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );
    await _storage.delete(
      key: AppConstants.refreshTokenKey,
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );
  }

  Future<void> clearAll() => _storage.deleteAll();
}
