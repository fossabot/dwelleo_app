# Work Order — Local Agents (VS Code / macOS)

Division of labor: **feature architecture + Dart implementation happen in the
Cowork sessions; anything requiring macOS, devices, signing or store accounts
runs locally.** Each task below is self-contained; run on `development` unless noted.

## 1 · Verify the repaired baseline (5 min)
```
git fetch && git checkout fix/geocoding-v5-and-validated-bumps
flutter clean && flutter pub get && flutter analyze && flutter test
flutter run --flavor dev -t lib/main_dev.dart   # iOS sim + Android emulator
```
Exercise the location picker (signup → location) — reverse geocoding must
resolve addresses (geocoding v5 migration). Then merge as PR.

## 2 · Fastlane bootstrap (macOS only)
- `brew install fastlane` (or bundler w/ Gemfile — prefer Gemfile committed).
- `cd ios && fastlane init` → adopt the handoff skeleton
  (`dwelleo_mobile_product_handoff/devops/fastlane/`) as reference, not verbatim.
- Lanes to create: `ios beta` (build → TestFlight), `android beta`
  (AAB → Firebase App Distribution), `android internal` (Play internal track later).
- Secrets NEVER in repo: App Store Connect API key (p8), keystore, service
  accounts → GitHub Actions secrets + local `.env` in gitignore.
  Names: `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8`, `ANDROID_KEYSTORE_B64`,
  `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`,
  `FIREBASE_APP_DIST_SA_JSON`.

## 3 · Wire CI to fastlane (after task 2)
- Extend `.github/workflows/ios_validation.yml` / `android_validation.yml`:
  on `development` push → `android beta` (App Distribution);
  on `release/*` → `ios beta` (TestFlight) with manual approval environment.
- Keep PR workflows build-only (no signing) — they must pass on forks.

## 4 · Device smoke matrix (each release candidate)
- iPhone (physical) + smallest supported simulator; 2 Android devices (one low-RAM).
- AR + RTL pass, dark/light, slow network (Network Link Conditioner), offline
  launch, dynamic type XL, VoiceOver/TalkBack on Home + Auth.

## 5 · GitHub admin (owner account, 10 min)
- Rulesets on `main` + `development`: PR required, 1 approval (2 for
  auth/payments/AI/security via CODEOWNERS), status checks = `flutter_quality`,
  conversation resolution, no force-push/deletion.
- Enable secret scanning + push protection; rotate the historical Maps keys.

## Out of scope for local agents (stays with architecture sessions)
Feature branches (PR-5+), API contract integration, state management, tests
design, parity with dwelleo.sa. Coordinate via `docs/audit/08` PR sequence.
