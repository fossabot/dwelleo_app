# iOS distribution — TestFlight (currently dormant)

## Where things stand

The iOS fastlane pipeline (`ios/fastlane/Fastfile`, lane `ios beta`) is written
and validated, but **dormant**. It cannot run yet because:

> **Every form of iOS over-the-air distribution — TestFlight *and* Firebase App
> Distribution — requires a paid Apple Developer Program membership ($99/yr).**
> There is no free path. The current account is a **free Apple ID** (personal
> team `Z28762D2MN`).

This is also the root cause of "the app disconnected after 7 days": a free
Apple ID signs apps with a **personal-team development profile that expires
after 7 days**. Paid membership raises development profiles to ~1 year and
unlocks TestFlight.

## Until the account is upgraded — local dev builds only

Install on your own device by rebuilding when the 7-day profile lapses:

```sh
flutter run --flavor dev -t lib/main_dev.dart          # debug on a connected device
# or a local release build on your device:
flutter run --release --flavor production -t lib/main_production.dart
```

Testers cannot receive iOS builds by email in this state. Android distribution
is unaffected and already live (see `SECRETS.md` → `android_distribute`).

## The "day you go paid" checklist

1. **Enrol** in the Apple Developer Program (https://developer.apple.com/programs/)
   and wait for activation (usually 24–48h).
2. **Register the app** in App Store Connect → Apps → **+** → New App, bundle id
   **`sa.dwelleo.app`** (the production flavor).
3. **Create an App Store Connect API key**: App Store Connect → Users and Access
   → Integrations → App Store Connect API → **+**. Role **App Manager**.
   Download the `AuthKey_XXXXXXXX.p8` (one-time download). Note the **Key ID**
   and the **Issuer ID**.
4. **Export the env vars** (locally, e.g. in `ios/fastlane/.env` — gitignored):
   ```sh
   export ASC_KEY_ID=XXXXXXXXXX
   export ASC_ISSUER_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
   export ASC_KEY_P8_PATH=/absolute/path/to/AuthKey_XXXXXXXX.p8
   # optional: export ASC_APPLE_ID=you@example.com
   ```
   Alternatively pass the key inline with `ASC_KEY_P8` (raw `.p8` contents).
5. **Confirm signing**: the Runner target uses **Automatic** signing with team
   `Z28762D2MN`. After enrolment, open `ios/Runner.xcworkspace` in Xcode once and
   let it create the distribution certificate + App Store provisioning profile.
6. **Ship it** (from repo root):
   ```sh
   cd ios && bundle exec fastlane ios beta
   ```
   This runs `flutter build ipa --flavor production -t lib/main_production.dart
   --export-method app-store` and uploads to TestFlight. Internal testers
   (added in App Store Connect → your app → TestFlight → Internal Testing) are
   emailed instantly; no device UDIDs to manage.

## Why TestFlight over Firebase App Distribution for iOS

Firebase App Distribution on iOS requires **ad-hoc** provisioning with every
tester's **device UDID** baked into the profile, and a rebuild whenever the
tester list changes. TestFlight adds testers by Apple ID email, scales to
thousands, and is the same pipe used for App Store submission — so iOS uses
TestFlight while Android uses Firebase App Distribution.

## Optional: move iOS builds into CI later

`ios beta` runs locally today (the chosen setup). To automate it on a GitHub
macOS runner later, add the App Store Connect API key as secrets
(`ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8` base64) and a distribution signing
strategy (e.g. `fastlane match` against a private certs repo). Note macOS runner
minutes bill at 10× on private repos.
