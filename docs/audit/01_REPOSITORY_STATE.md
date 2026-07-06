# Repository Current-State Report

Snapshot: `development` @ merge of PR #6 (`feat/home_screen`) + 3 follow-up commits
(`remember-me/route guard`, `home fixes`, `status bar/splash/Maps key hardening`).

## Branches & remote

| Ref | Notes |
|---|---|
| `main` | production target; behind `development` |
| `development` | integration branch (current) |
| `feat/project-foundation`, `feat/onboarding-splash`, `feat/login-signup`, `feat/home_screen` | merged history, may be pruned |
| `chore/foundation-docs` | docs branch |
| Tags / Releases | **none** |
| `.github/workflows` | **none** |
| fastlane | **none** |
| Branch protections / rulesets / open PRs / issues | **unverified** — needs GitHub-side check (no API auth from audit env). Required-review enforcement was not demonstrated by PR #7 |

## Toolchain & flavors

- Flutter (repo-tested): 3.44.4 stable / Dart 3.12.2. SDK constraint `^3.11.5`.
- Entry points: `main.dart`, `main_dev.dart`, `main_staging.dart`, `main_production.dart`; `bootstrap.dart` initializes Firebase, Crashlytics, Performance, service locator.
- Android: 1 `productFlavors` block; iOS: shared dev, staging, and production schemes are present under `ios/Runner.xcodeproj/xcshareddata/xcschemes/`.
- **Committed config of note:** `android/app/google-services.json` (Firebase client configuration, in-repo; requires Security Rules, App Check, API-key restriction, and environment review), `l10n.yaml`, launcher/splash configs.

## Modules (verified by inspection)

| Module | State |
|---|---|
| onboarding, auth (login/register/OTP/forgot, remember-me, route guard) | implemented, live-tested |
| properties (list/detail, Spatie filters, saved via `filter[is_favorite]`) | implemented; filters UI minimal |
| home (nav strip, search card + recents, featured, projects, City Intelligence table, market map w/ districts, partners) | implemented on live endpoints |
| explore (projects browser) | implemented |
| subscriptions / ai_search / profile | branded stubs (API plans list is live-but-empty) |
| core | DI, Dio(+refresh Dio), interceptors (auth/locale/logging), typed Failures/ApiResult, secure storage, lookup service, recent-searches store, image-optimizer bridge, HTML sanitizer, formatters, motion kit |

## Dependencies of note

- Declared-but-unwired: `freerasp`, `amplitude_flutter`, `posthog_flutter` (partially), `fl_chart` (unused since chart→table), `local_auth`, `record`.
- `firebase_app_check` declared; enforcement state unverified.

## Tests

50 tests, all green at HEAD (models/envelope parsing incl. captured buy/rent market
shapes, repository failure mapping, HomeCubit section isolation, MarketStatsCubit
cache, ExploreCubit, RecentSearchesStore, HtmlText, app-boot widget test).

## Build health (executed 2026-07-06, Linux/ARM sandbox, Flutter 3.44.4)

| Command | Result | Root cause / note |
|---|---|---|
| `flutter pub get` | ✅ exit 0 | incl. uncommitted bumps |
| `flutter analyze` (HEAD deps) | ✅ 0 issues | |
| `flutter analyze` (uncommitted bumps) | ❌ 3 errors | **geocoding 4→5 breaking change** in `lib/core/widgets/location_picker.dart:78,87` + unused import |
| `flutter analyze` (maintainer machine profile) | 406 issues, **403 from `build/`** | `analysis_options.yaml` lacks `analyzer: exclude: [build/**]` |
| `flutter test` (HEAD deps) | ✅ 50/50 | |
| `flutter test` (bumps) | ❌ 49/50 | widget test compile failure = same geocoding break |
| Android/iOS builds | ⛔ not executable in audit env | no Android SDK / no Xcode; CI must own (PR-4). iOS builds evidenced on maintainer Mac (`Podfile.lock`, `build/ios/*`) |

## Uncommitted-changes register (working tree at audit time)

- `pubspec.yaml` + `pubspec.lock`: dependency bump batch observed during PR-1 audit (cupertino_icons, dio 5.10, equatable 2.1, connectivity/package_info/device_info majors, **geocoding→5 BREAKING**). → PR-2 must validate each dependency individually; do not accept a bulk update merely because `pub get` succeeds.
- `android/gradle.properties`, `ios/Podfile.lock`, Xcode swiftpm/scheme-backup, `.vscode/` → local env noise; gitignore review in PR-2.
