# CI/CD secrets

The Firebase config and signing/distribution inputs are **gitignored** (they
carry project keys and credentials). CI materializes them from GitHub secrets;
locally they live at the gitignored paths noted below. Nothing in this table is
ever committed.

## GitHub Actions secrets

Add these at **GitHub → repo → Settings → Secrets and variables → Actions →
New repository secret**.

| Secret | Encoding | Consumed by | Produce it with |
|---|---|---|---|
| `GOOGLE_SERVICES_JSON` | base64 | `android_validation`, `android_distribute` | `base64 -i android/app/google-services.json \| pbcopy` |
| `GOOGLE_SERVICE_INFO_DEV` | base64 | `ios_validation` | `base64 -i ios/config/GoogleService-Info-dev.plist \| pbcopy` |
| `GOOGLE_SERVICE_INFO_STAGING` | base64 | `ios_validation` | `base64 -i ios/config/GoogleService-Info-staging.plist \| pbcopy` |
| `MAPS_API_KEY` | plain text | `android_validation`, `ios_validation`, `android_distribute` | the Android Maps SDK key (value only, no `MAPS_API_KEY=` prefix) |
| `FIREBASE_SERVICE_ACCOUNT_JSON` | base64 | `android_distribute` | `base64 -i android/fastlane/firebase-service-account.json \| pbcopy` |

> `base64` on macOS emits a single line, which is what these workflows expect
> (`openssl base64 -d -A`). On Linux, use `base64 -w0 <file>`.

CI decodes each base64 secret back to its gitignored path immediately before the
build; the plain-text `MAPS_API_KEY` is written into `android/secrets.properties`
and `ios/Flutter/Secrets.xcconfig`.

## Local credential paths (gitignored — never commit)

| Purpose | Local path |
|---|---|
| Android Firebase config | `android/app/google-services.json` |
| iOS Firebase config (per flavor) | `ios/config/GoogleService-Info-{dev,staging,production}.plist` |
| Android Maps key | `android/secrets.properties` → `MAPS_API_KEY=…` |
| iOS Maps key | `ios/Flutter/Secrets.xcconfig` → `MAPS_API_KEY=…` |
| Firebase service account (App Distribution) | `android/fastlane/firebase-service-account.json` |

`.gitignore` covers every path above. Verify any file is ignored with
`git check-ignore -v <path>` before committing.

## Firebase service account

App Distribution uploads authenticate with a **service account**, not the
deprecated `firebase login:ci` token.

1. The account `fastlane-supply@dwelleo-60f38.iam.gserviceaccount.com` already
   exists. Grant it the **Firebase App Distribution Admin** role
   (`roles/firebaseappdistro.admin`) in **Google Cloud → IAM** on project
   `dwelleo-60f38`. (It was created for Play "supply"; App Distribution needs
   this role added.)
2. Save its key JSON as `android/fastlane/firebase-service-account.json`
   (gitignored).
3. For CI, base64 it into `FIREBASE_SERVICE_ACCOUNT_JSON` (see table above).

## Not required yet

iOS TestFlight distribution needs a **paid Apple Developer Program** account and
its own App Store Connect API-key secrets. Those are documented separately in
[`IOS_TESTFLIGHT.md`](./IOS_TESTFLIGHT.md) and stay dormant until the membership
is active.
