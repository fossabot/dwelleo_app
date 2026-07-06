# CI quality gates

PR-4 adds source-controlled GitHub Actions checks for pull requests and pushes to `development` and `main`.

## Required-check candidates

Configure these as required status checks after the workflows have run at least once:

| Workflow | Job/check name | Purpose |
|---|---|---|
| Flutter Quality | `quality / format-analyze-test` | pub get, localization generation, format, analyze, tests with coverage artifact |
| Android Validation | `android / dev-staging debug APKs` | Java 17 + dev/staging debug APK builds on Ubuntu |
| iOS Validation | `ios / dev-staging simulator builds` | dev/staging simulator builds on macOS with CocoaPods |
| Dependency Review | `security / dependency review` | dependency review on pull requests where GitHub supports it |

## Workflow design notes

- All workflows use minimal `contents: read` permissions except dependency review, which also needs `pull-requests: read`.
- Workflow concurrency cancels superseded runs per workflow/ref.
- Flutter is pinned to `3.44.4` stable.
- Cache keys include `pubspec.lock`; CocoaPods cache also includes `ios/Podfile.lock`.
- Artifact retention is 14 days for coverage and Android debug APKs.
- Android validation builds dev/staging debug APKs only and does not require production signing secrets.
- iOS validation builds dev/staging simulator artifacts with `--no-codesign`; it does not require signing assets.
- Production release signing, TestFlight, Play internal tracks, and environment-protected deployments remain out of scope for PR-4.

## Checks that only prove out after push

- Required status-check names are visible to branch protection only after the workflows run on GitHub at least once.
- `actions/dependency-review-action` behavior depends on repository visibility, GitHub plan, and dependency graph availability.
- macOS/iOS simulator validation requires GitHub-hosted macOS runners or equivalent self-hosted macOS runners.
