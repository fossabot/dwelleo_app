# Mobile flavors and environments

Date: 2026-07-06

Dwelleo keeps the canonical flavor names `dev`, `staging`, and `production` across Flutter, Android, iOS, and Dart entry points.

## Alignment matrix

| Flavor | Dart entry point | Android application ID | iOS bundle ID | Display name | API base URL | Analytics environment | Logging | Firebase native config |
|---|---|---|---|---|---|---|---|---|
| dev | `lib/main_dev.dart` | `sa.dwelleo.app.dev` | `sa.dwelleo.app.dev` | `Dwelleo Dev` | `https://api.dwelleo.sa` | `dev` | verbose, redacted headers | local/CI supplied client config; pending project/restriction review |
| staging | `lib/main_staging.dart` | `sa.dwelleo.app.staging` | `sa.dwelleo.app.staging` | `Dwelleo Staging` | `https://staging-api.dwelleo.sa` | `staging` | reduced path/status logging | local/CI supplied client config; pending project/restriction review |
| production | `lib/main_production.dart` | `sa.dwelleo.app` | `sa.dwelleo.app` | `Dwelleo` | `https://api.dwelleo.sa` | `production` | minimal/no request logging | local/CI supplied client config; pending Rules/App Check/API restriction review |

## Confirmed and pending environment facts

- `dev` currently points at the live production API. This is a known risk preserved from repository state; PR-3 does **not** silently change it or invent a development backend.
- The `staging` API value exists in repository code but still needs backend confirmation before release claims.
- Official Firebase project/app IDs and production restriction posture remain pending. Do not commit service accounts, privileged Firebase keys, signing files, or production secrets.
- Android product flavors are declared in `android/app/build.gradle.kts` for `dev`, `staging`, and `production`.
- iOS shared schemes are present for `dev`, `staging`, and `production` under `ios/Runner.xcodeproj/xcshareddata/xcschemes/`.

## Firebase strategy

Firebase files are client configuration, not service-account credentials, but they still require review:

- Android: provide the appropriate `google-services.json` locally or through CI for the selected application ID.
- iOS: provide `ios/config/GoogleService-Info-<flavor>.plist` locally or through CI and copy it into the bundle as `GoogleService-Info.plist` during flavor builds.
- All Firebase projects must be reviewed for Security Rules, App Check enforcement, API-key restrictions, analytics separation, and Crashlytics/Performance environment labeling.

## Maps strategy

- Android Maps key is injected from gitignored `android/secrets.properties` as `MAPS_API_KEY`.
- iOS Maps key is read from `$(MAPS_API_KEY)` in `Info.plist`; provide it through local/CI xcconfig.
- Use platform-restricted Maps keys. Do not commit unrestricted web keys or production secrets.

## Run commands

```sh
flutter run --flavor dev -t lib/main_dev.dart
flutter run --flavor staging -t lib/main_staging.dart
flutter run --flavor production -t lib/main_production.dart
```

## Android debug build commands

```sh
flutter build apk --debug --flavor dev -t lib/main_dev.dart
flutter build apk --debug --flavor staging -t lib/main_staging.dart
```

## iOS simulator build commands

Run only on macOS with Xcode installed:

```sh
flutter build ios --simulator --flavor dev -t lib/main_dev.dart
flutter build ios --simulator --flavor staging -t lib/main_staging.dart
flutter build ios --simulator --flavor production -t lib/main_production.dart
```
