# Dwelleo Mobile App

> A production-upgrade Flutter implementation of Dwelleo’s Saudi real-estate experience for iOS and Android.

<p align="center">
  <img src="https://github.com/user-attachments/assets/cf2335c8-c707-4116-b1ba-727df169f9e4" alt="Dwelleo Mobile App banner" />
</p>

<p align="center">
  <img alt="Status" src="https://img.shields.io/badge/status-active%20development-orange" />
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-stable-02569B?logo=flutter" />
  <img alt="Dart" src="https://img.shields.io/badge/Dart-%5E3.11.5-0175C2?logo=dart" />
  <img alt="Platforms" src="https://img.shields.io/badge/platforms-iOS%20%7C%20Android-lightgrey" />
  <img alt="Locales" src="https://img.shields.io/badge/locales-Arabic%20%7C%20English-2ea44f" />
  <img alt="Architecture" src="https://img.shields.io/badge/architecture-feature--first%20clean%20architecture-6f42c1" />
</p>

## Project status

This repository is under active development and is being upgraded toward a production-quality Dwelleo mobile application.

It is **not yet a store-ready production release**. Release signing, final backend contracts, native subscription entitlement validation, complete CI/CD, security hardening, accessibility validation, and store review preparation still require completion and approval.

The default integration branch is `development`.

## About the project

Dwelleo is publicly positioned as a Saudi AI-powered PropTech platform focused on verified property data, intelligent search, market insights, developers, brokers, subscriptions, and AI-assisted real-estate journeys.

This Flutter project translates that public product direction into a native mobile experience rather than wrapping the website in a WebView. The mobile product is intended to support:

- Property discovery for buying, renting, off-plan, and commercial listings.
- Arabic and English experiences with RTL and LTR support.
- Verified property, developer, broker, and agent information.
- AI-assisted property search.
- Market intelligence and investment-oriented insights.
- Saved properties, comparisons, contact actions, and role-aware experiences.
- Developer-facing capabilities after backend and product approval.

Public product reference: [dwelleo.sa/en](https://dwelleo.sa/en)

> This repository is a technical implementation and production-upgrade project. It should not be represented as an official released Dwelleo application until Dwelleo approves the product, branding, backend integration, legal content, and store distribution.

## Product alignment

The target mobile scope is based on the public Dwelleo experience and the reviewed production handoff.

| Public capability | Mobile direction | Current state |
|---|---|---|
| Buy, rent, off-plan, and commercial discovery | Native search, filters, lists, and property details | In progress |
| Verified properties and trusted market data | Verified badges, source attribution, and structured details | In progress |
| AI Search | Conversational property discovery with matched results | Initial module present |
| Market Intelligence | Price statistics, trends, area insights, and market visualizations | Partial foundation |
| Featured developers and brokers | Native discovery and profile experiences | Planned |
| Travel-time property search | Destination, maximum time, transport mode, and map workflow | Planned |
| Subscriptions | Free and paid access with store-compliant entitlements | UI foundation present; billing pending |
| AI Sales Agent | Bilingual, voice-first developer sales workflow using BITEP | Planned; requires product and backend confirmation |

The detailed public AI Sales Agent experience describes the **BITEP** qualification framework:

- Budget
- Intent
- Timeline
- Eligibility
- Preferences

AI Search and AI Sales Agent are separate products and should not be implemented as one generic chatbot.

## Implemented repository foundation

The current codebase includes:

- Flutter entry points for development, staging, and production.
- Android product flavors and matching iOS schemes.
- Centralized application bootstrap.
- Feature-first project organization.
- BLoC/Cubit state management.
- `get_it` dependency injection.
- Dio networking foundation.
- `go_router` navigation with session-aware redirects.
- Secure session storage.
- Firebase Core, Analytics, Crashlytics, Performance, Messaging, Remote Config, and App Check dependencies.
- Arabic and English localization using ARB files.
- Light and dark themes.
- Google Maps and geolocation dependencies.
- Voice recording and permission dependencies.
- Initial screens and flows for onboarding, authentication, home, explore, AI Search, saved properties, subscriptions, profile, property search, and property details.

## Current application routes

The active router currently includes:

### Onboarding and authentication

- Onboarding
- Language selection
- Login
- Forgot password
- Role selection
- Sign-up form
- OTP verification

### Main navigation

- Home
- Explore
- AI Search
- Saved properties
- Profile

### Additional routes

- Subscriptions
- Property search
- Property details

A route being present does not automatically mean its backend contract, analytics, edge cases, security review, and production acceptance criteria are complete.

## Technology stack

| Area | Current implementation |
|---|---|
| Framework | Flutter |
| Language | Dart `^3.11.5` |
| Architecture | Feature-first Clean Architecture |
| State management | `flutter_bloc` / Cubit |
| Dependency injection | `get_it` |
| Navigation | `go_router` |
| Networking | Dio |
| Secure storage | `flutter_secure_storage` |
| Preferences | `shared_preferences` |
| Localization | `flutter_localizations`, `intl`, ARB files |
| Firebase | Core, Analytics, Crashlytics, Performance, Messaging, Remote Config, App Check |
| Maps and location | `google_maps_flutter`, `geolocator`, `geocoding` |
| Voice input | `record`, `permission_handler` |
| Analytics SDKs | Firebase Analytics, Amplitude, PostHog |
| Runtime protection | freeRASP dependency |
| Testing | Flutter Test and Mocktail |

Dependencies such as Drift, SQLite, SQLCipher, native in-app purchases, or another storage framework must not be described as implemented until they are added and integrated in the repository.

## Architecture

The project follows feature-first Clean Architecture with clear boundaries between presentation, domain, and data concerns.

```text
lib/
├── app/
│   ├── app.dart
│   └── app_shell.dart
├── core/
│   ├── config/
│   ├── di/
│   ├── localization/
│   ├── network/
│   ├── routing/
│   ├── session/
│   ├── storage/
│   ├── theme/
│   └── widgets/
├── features/
│   ├── ai_search/
│   ├── auth/
│   ├── home/
│   ├── onboarding/
│   ├── profile/
│   ├── properties/
│   └── subscriptions/
├── l10n/
├── bootstrap.dart
├── main.dart
├── main_dev.dart
├── main_staging.dart
└── main_production.dart
```

Feature modules should preserve the following separation where applicable:

```text
feature/
├── data/
│   ├── datasources/
│   ├── models/
│   └── repositories/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
└── presentation/
    ├── bloc/
    ├── screens/
    └── widgets/
```

## Environments and flavors

The repository defines three application environments.

| Flavor | Dart entry point | Android application ID | API base URL |
|---|---|---|---|
| `dev` | `lib/main_dev.dart` | `sa.dwelleo.app.dev` | `https://api.dwelleo.sa` |
| `staging` | `lib/main_staging.dart` | `sa.dwelleo.app.staging` | `https://staging-api.dwelleo.sa` |
| `production` | `lib/main_production.dart` | `sa.dwelleo.app` | `https://api.dwelleo.sa` |

The development flavor currently points to the live API by design because a separate development backend is not configured. Use care when testing write operations.

Matching shared iOS schemes exist for:

- `dev`
- `staging`
- `production`

## Getting started

### Prerequisites

- Flutter stable compatible with Dart `^3.11.5`
- Android Studio for Android development
- Xcode and CocoaPods for iOS development
- A valid Firebase configuration for the selected environment
- A Google Maps API key for map rendering
- Access to the required Dwelleo backend environment

Check your local environment:

```bash
flutter doctor -v
dart --version
```

### Clone and install

```bash
git clone https://github.com/hakemm663/dwelleo_app.git
cd dwelleo_app
flutter pub get
flutter gen-l10n
```

## Running the app

### Development

```bash
flutter run --flavor dev -t lib/main_dev.dart
```

### Staging

```bash
flutter run --flavor staging -t lib/main_staging.dart
```

### Production configuration

```bash
flutter run --flavor production -t lib/main_production.dart
```

The production flavor command validates the production configuration path. It does not by itself mean that the build is signed, approved, or ready for store distribution.

## Native configuration

### Google Maps on Android

Create the ignored file:

```text
android/secrets.properties
```

Add:

```properties
MAPS_API_KEY=your_android_maps_api_key
```

When the file is missing, the Android build can still start, but maps will not render correctly.

### Firebase

The bootstrap initializes Firebase using the native configuration selected by the active application ID or Xcode scheme.

Provide the correct client configuration for each environment according to the project’s native setup. Never commit:

- Firebase service-account private keys
- App Store Connect private keys
- Android signing keystores
- Signing passwords
- Private backend tokens
- AI provider secrets
- Payment-provider secrets

Firebase client configuration and server-side service-account credentials are not the same. Follow the repository security policy for client configuration files, and never embed privileged server credentials in the mobile app.

### API configuration

API environment values are currently defined in:

```text
lib/core/config/app_config.dart
```

The project does not currently load `.env.dev`, `.env.staging`, or `.env.prod` files. Do not add README instructions for environment files unless the application is updated to use them.

## Localization

Localization configuration is defined in `l10n.yaml`.

Source files:

```text
lib/l10n/app_en.arb
lib/l10n/app_ar.arb
```

Regenerate localizations after changing ARB files:

```bash
flutter gen-l10n
```

Every production feature should be reviewed in:

- English LTR
- Arabic RTL
- Light mode
- Dark mode
- Large text sizes
- Screen-reader navigation

## Quality checks

Run the local quality gate before opening a pull request:

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

Validate Android flavors:

```bash
flutter build apk --debug --flavor dev -t lib/main_dev.dart
flutter build apk --debug --flavor staging -t lib/main_staging.dart
flutter build appbundle --release --flavor production -t lib/main_production.dart
```

Validate iOS on macOS:

```bash
flutter build ios --simulator --flavor dev -t lib/main_dev.dart
flutter build ios --simulator --flavor staging -t lib/main_staging.dart
flutter build ios --release --flavor production -t lib/main_production.dart
```

Do not claim a command has passed unless it has been executed successfully in the relevant environment.

## Production-readiness gaps

The following items must be completed or verified before release:

- Replace Android debug signing in the release build with protected production signing.
- Verify iOS signing, capabilities, bundle IDs, and provisioning profiles.
- Confirm all backend endpoints and request/response contracts.
- Add complete token-refresh and session-expiration test coverage.
- Validate account deletion and privacy workflows.
- Complete native subscription billing and server-side entitlement validation.
- Add restore-purchase behavior where required.
- Complete AI safety, fallback, privacy, observability, and quota handling.
- Finalize maps, travel-time search, and location permission fallbacks.
- Add production CI/CD with protected secrets and manual release approvals.
- Complete accessibility and Arabic RTL testing.
- Complete App Store and Google Play policy reviews.
- Perform security, privacy, legal, and Saudi PDPL reviews with qualified owners.

## Branching workflow

Long-lived branches:

- `main`: production-ready releases only
- `development`: integration branch for reviewed work

Short-lived branches should use clear prefixes:

```text
feature/<scope>
fix/<scope>
refactor/<scope>
chore/<scope>
docs/<scope>
test/<scope>
hotfix/<scope>
release/<version>
```

Recommended merge flow:

```text
short-lived branch -> pull request -> development -> release branch -> main
```

Avoid combining architecture refactors, new features, signing changes, and backend-contract changes in one pull request.

## Roadmap

### Foundation hardening

- Confirm flavor configuration across Android and iOS.
- Finalize secure configuration handling.
- Complete CI quality gates.
- Improve failure mapping, retries, and observability.

### Authentication production readiness

- Validate login, registration, OTP, password reset, logout, and session restoration.
- Complete token refresh and account deletion.
- Confirm supported user roles with Dwelleo.

### Marketplace parity

- Complete buy, rent, off-plan, and commercial discovery.
- Complete filters, pagination, sorting, map/list views, save, and compare.
- Complete property contact and lead-ingestion flows.

### Ecosystem and intelligence

- Developers, brokers, agents, and projects.
- Market hub, price statistics, trends, rental returns, and area insights.
- Travel-time discovery.

### AI products

- Production AI Search contracts and guardrails.
- Voice query handling.
- Structured property matches and safe fallbacks.
- AI Sales Agent only after product, backend, security, legal, and role authorization are confirmed.

### Monetization and release

- Native subscriptions and entitlement synchronization.
- TestFlight and Google Play internal testing.
- Store metadata, privacy declarations, and release automation.

## Security principles

- Never log access tokens, refresh tokens, personal information, payment data, or AI conversation secrets.
- Keep verbose Dio logging disabled in release builds.
- Store session tokens only in secure storage.
- Validate authorization on the backend; client-side role checks are not sufficient.
- Restrict API keys by platform, application ID, bundle ID, and allowed APIs.
- Treat AI output as untrusted until validated.
- Redact sensitive information from analytics and crash reports.
- Never place server secrets in Flutter assets, Dart source, native resource files, or repository history.

## References

- [Dwelleo public website](https://dwelleo.sa/en)
- [Dwelleo AI Sales Agent](https://dwelleo.sa/en/ai-Sales)
- [Flutter flavor documentation](https://docs.flutter.dev/deployment/flavors)
- [Flutter testing documentation](https://docs.flutter.dev/testing)
- [GitHub README guidance](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-readmes)

## Maintainer

**Mohamed Hakem**  
GitHub: [@hakemm663](https://github.com/hakemm663)

## License and brand notice

This repository is marked as proprietary and is intended for professional evaluation and controlled project development.

Dwelleo names, logos, product language, website content, and brand assets belong to their respective owner. Their inclusion in this repository does not by itself establish authorization, partnership, employment, or official release status.
