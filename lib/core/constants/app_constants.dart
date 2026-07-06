abstract final class AppConstants {
  static const String appName = 'Dwelleo';
  static const String defaultLocale = 'en';
  static const List<String> supportedLocales = ['en', 'ar'];

  // Token storage keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String localeKey = 'locale';
  static const String themeModeKey = 'theme_mode';
  static const String onboardingDoneKey = 'onboarding_done';
  static const String rememberMeKey = 'remember_me';

  // Network timeouts (ms). The dwelleo API can be slow on cold auth requests,
  // so the receive window is generous to avoid spurious timeouts.
  static const int connectTimeout = 20000;
  static const int receiveTimeout = 45000;

  // Pagination
  static const int defaultPageSize = 20;

  // Cache durations
  static const Duration lookupCacheDuration = Duration(hours: 24);
}
