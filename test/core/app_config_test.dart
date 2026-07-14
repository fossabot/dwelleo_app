import 'package:dwelleo_app/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppConfig', () {
    test(
      'dev uses canonical dev labels and explicitly known production API risk',
      () {
        AppConfig.init(Flavor.dev);

        final config = AppConfig.instance;

        expect(config.flavorName, 'dev');
        expect(config.displayName, 'Dwelleo Dev');
        expect(config.apiBaseUrl, 'https://api.dwelleo.sa');
        expect(config.analyticsEnvironment, 'dev');
        expect(config.logLevel, AppLogLevel.verbose);
        expect(config.usesProductionApi, isTrue);
        expect(config.backendStatus, contains('development backend'));
      },
    );

    test('staging uses reduced logging and pending backend status', () {
      AppConfig.init(Flavor.staging);

      final config = AppConfig.instance;

      expect(config.flavorName, 'staging');
      expect(config.displayName, 'Dwelleo Staging');
      expect(config.analyticsEnvironment, 'staging');
      expect(config.logLevel, AppLogLevel.standard);
      expect(config.usesProductionApi, isFalse);
      expect(config.backendStatus, contains('pending'));
    });

    test('production uses minimal logging and live API', () {
      AppConfig.init(Flavor.production);

      final config = AppConfig.instance;

      expect(config.flavorName, 'production');
      expect(config.displayName, 'Dwelleo');
      expect(config.apiBaseUrl, 'https://api.dwelleo.sa');
      expect(config.analyticsEnvironment, 'production');
      expect(config.logLevel, AppLogLevel.minimal);
      expect(config.usesProductionApi, isTrue);
    });
  });
}
