/// Build flavors. The running flavor is selected by the entry point
/// (`main_dev` / `main_staging` / `main_production`), making the entry point
/// the single source of truth rather than a `--dart-define` that can be
/// forgotten.
enum Flavor { dev, staging, production }

enum AppLogLevel { verbose, standard, minimal }

/// Runtime configuration derived from the active [Flavor].
///
/// Initialized once in `bootstrap()` (or a test's setUp) via [AppConfig.init].
/// Reading [instance] before init throws, so a forgotten init surfaces loudly
/// instead of silently running as the wrong flavor.
class AppConfig {
  const AppConfig._({
    required this.flavor,
    required this.apiBaseUrl,
    required this.analyticsEnvironment,
    required this.logLevel,
    required this.firebaseConfigStatus,
    required this.usesProductionApi,
    required this.backendStatus,
  });

  static AppConfig? _instance;

  static AppConfig get instance {
    final config = _instance;
    if (config == null) {
      throw StateError(
        'AppConfig.init(flavor) must be called before AppConfig.instance '
        '(done in bootstrap()).',
      );
    }
    return config;
  }

  static void init(Flavor flavor) => _instance = _forFlavor(flavor);

  static AppConfig _forFlavor(Flavor flavor) => switch (flavor) {
    Flavor.dev => const AppConfig._(
      flavor: Flavor.dev,
      // Confirmed repository state: no separate development backend is wired.
      // Keep this explicit so PR-3 does not silently invent or switch endpoints.
      apiBaseUrl: 'https://api.dwelleo.sa',
      analyticsEnvironment: 'dev',
      logLevel: AppLogLevel.verbose,
      firebaseConfigStatus:
          'pending per-flavor Firebase client config review; local/CI supplied',
      usesProductionApi: true,
      backendStatus: 'pending dedicated development backend',
    ),
    Flavor.staging => const AppConfig._(
      flavor: Flavor.staging,
      // Unconfirmed: documented as pending rather than invented as official.
      apiBaseUrl: 'https://staging-api.dwelleo.sa',
      analyticsEnvironment: 'staging',
      logLevel: AppLogLevel.standard,
      firebaseConfigStatus:
          'pending per-flavor Firebase client config review; local/CI supplied',
      usesProductionApi: false,
      backendStatus: 'pending backend confirmation',
    ),
    Flavor.production => const AppConfig._(
      flavor: Flavor.production,
      apiBaseUrl: 'https://api.dwelleo.sa',
      analyticsEnvironment: 'production',
      logLevel: AppLogLevel.minimal,
      firebaseConfigStatus:
          'pending production Firebase restriction, Rules, and App Check review',
      usesProductionApi: true,
      backendStatus: 'confirmed live API base URL',
    ),
  };

  final Flavor flavor;
  final String apiBaseUrl;
  final String analyticsEnvironment;
  final AppLogLevel logLevel;
  final String firebaseConfigStatus;
  final bool usesProductionApi;
  final String backendStatus;

  bool get isDev => flavor == Flavor.dev;
  bool get isStaging => flavor == Flavor.staging;
  bool get isProduction => flavor == Flavor.production;

  String get flavorName => flavor.name;

  String get displayName => switch (flavor) {
    Flavor.dev => 'Dwelleo Dev',
    Flavor.staging => 'Dwelleo Staging',
    Flavor.production => 'Dwelleo',
  };
}
