fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## Android

### android build_dev

```sh
[bundle exec] fastlane android build_dev
```

Assemble a dev release APK → build/app/outputs/flutter-apk/app-dev-release.apk

### android build_staging

```sh
[bundle exec] fastlane android build_staging
```

Assemble a staging release APK → build/app/outputs/flutter-apk/app-staging-release.apk

### android build_production

```sh
[bundle exec] fastlane android build_production
```

Assemble a production release APK → build/app/outputs/flutter-apk/app-production-release.apk

### android build_production_aab

```sh
[bundle exec] fastlane android build_production_aab
```

Assemble a production release AAB (debug-signed; not yet Play-ready)

### android firebase_distribution

```sh
[bundle exec] fastlane android firebase_distribution
```

Build the production APK and ship it to Firebase App Distribution. Triggered automatically on push to development; runnable locally once android/fastlane/firebase-service-account.json is in place.

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
