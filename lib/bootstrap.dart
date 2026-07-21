import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'app/app.dart';
import 'core/config/app_config.dart';
import 'core/di/service_locator.dart';
import 'core/localization/locale_cubit.dart';
import 'core/session/session_state.dart';
import 'core/storage/secure_storage.dart';
import 'core/theme/theme_cubit.dart';

/// Brings up Firebase + Crashlytics error routing. Never rethrows: a telemetry
/// failure must not block app launch.
Future<void> _initFirebase(AppConfig config) async {
  try {
    // Reads the per-flavor native config: android/app/google-services.json
    // (selected by applicationId) and the GoogleService-Info.plist copied
    // into the iOS bundle by the flavor build phase.
    await Firebase.initializeApp();
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  } catch (error, stack) {
    // Keep production startup diagnostics minimal and non-sensitive.
    if (config.isProduction) {
      debugPrint('Firebase initialization failed.');
    } else {
      debugPrint('Firebase initialization failed: $error\n$stack');
    }
  }
}

/// Single startup path shared by every flavor entry point
/// (`main_dev` / `main_staging` / `main_production`). The [flavor] is passed in
/// by the entry point, so the running environment is unambiguous.
Future<void> bootstrap(Flavor flavor) async {
  // Must run before the zone is established so binding errors are not swallowed
  // by the zone handler before the handler itself is set up.
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.init(flavor);
  final config = AppConfig.instance;

  runZonedGuarded(
    () async {
      // Registration only — every dependency is a lazy singleton, so this does
      // no I/O and must complete before any sl<> lookup below.
      await setupServiceLocator();
      final storage = sl<SecureStorage>();

      // PERF: every await below is an independent platform round-trip
      // (Firebase channel + five Keychain/EncryptedSharedPreferences reads).
      // Started together so the native splash waits ONE round-trip instead of
      // six serial ones — the serial chain was costing multi-second cold starts
      // on iOS, where each first Keychain hit is expensive.
      final firebaseReady = _initFirebase(config);
      final localeReady = sl<LocaleCubit>().init();
      final themeReady = sl<ThemeCubit>().init();
      final onboardingRead = storage.isOnboardingDone();
      final rememberMeRead = storage.getRememberMe();
      final tokenRead = storage.getAccessToken();

      await Future.wait([firebaseReady, localeReady, themeReady]);

      // Restore session for the router guard. If the last login didn't ask to
      // be remembered, drop the persisted token so a cold start requires login.
      final onboardingDone = await onboardingRead;
      final rememberMe = await rememberMeRead;
      var token = await tokenRead;
      if (token != null && !rememberMe) {
        await storage.clearAuth();
        token = null;
      }
      sl<SessionState>()
        ..onboardingDone = onboardingDone
        ..isLoggedIn = token != null;

      runApp(const DwelleoApp());
    },
    (error, stack) {
      // Reporting must never throw out of the last-resort handler.
      try {
        if (Firebase.apps.isNotEmpty) {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        }
      } catch (_) {}
      if (config.isProduction) {
        debugPrint('Uncaught zone error.');
      } else {
        debugPrint('Uncaught zone error: $error\n$stack');
      }
    },
  );
}
