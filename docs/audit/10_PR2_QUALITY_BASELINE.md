# PR-2 Quality Baseline Notes

Date: 2026-07-06

## ADR-lite: geocoding dependency

**Decision:** keep `geocoding` pinned to the current 4.x line for PR-2 (`^4.0.0`) instead of migrating to 5.x in the quality-baseline PR.

**Context:** `lib/core/widgets/location_picker.dart` currently uses `placemarkFromCoordinates(latitude, longitude)`, which is compatible with the installed `geocoding` 4.0.0 API. The earlier audit observed that a bulk upgrade to `geocoding` 5 caused analyzer and widget-test compile failures in this widget.

**Alternatives considered:**

1. Migrate the location picker to `geocoding` 5 immediately.
2. Temporarily pin `geocoding` 4 and defer the migration until the API delta can be validated on iOS and Android devices/simulators.

**Migration impact:** staying on 4.x keeps the existing reverse-geocoding behavior unchanged for the quality baseline and avoids introducing a platform-plugin behavior change before flavor and CI rails exist.

**Rollback / forward path:** if a future PR validates `geocoding` 5 on both target platforms, update `pubspec.yaml`, run `flutter pub get`, migrate affected call sites, and rerun the full analyze/test/build matrix. If the future migration regresses, revert that dependency and call-site commit to return to this baseline.

## Dependency validation

No bulk dependency update is accepted in PR-2. The locked dependency set is retained, with `geocoding` intentionally staying at 4.0.0. Direct dependencies were checked with repository search for package imports/usages.

Dependencies with current direct code usage include Dio, get_it, Flutter BLoC, Equatable, go_router, secure storage, shared preferences, cached network image, flutter_svg, intl, geolocator, Google Maps Flutter, Firebase Core/Crashlytics, intl_phone_field, geocoding, and mocktail.

Dependencies currently declared for planned or platform work but not yet wired in production code include `freerasp`, `amplitude_flutter`, `posthog_flutter`, `fl_chart`, `local_auth`, `record`, `connectivity_plus`, `package_info_plus`, `device_info_plus`, Firebase Analytics/Performance/Messaging/Remote Config/App Check, and `permission_handler`. They are not removed in PR-2 because upcoming security, analytics, voice/search, platform, and environment work may wire them, and dependency removal should not create churn before those scoped PRs.

## Localization validation

`tool/validate_l10n.sh` is the CI-ready localization validation command for this baseline. It fails when `l10n.yaml`, `lib/l10n/app_en.arb`, or `lib/l10n/app_ar.arb` are missing, then runs `flutter gen-l10n` so generation errors fail the command.
