# iOS Firebase configuration (per flavor)

The app builds three flavors — **dev**, **staging**, **production** — each mapped
to its own Firebase iOS app and bundle id:

| Flavor      | Bundle id               | Required file                          |
| ----------- | ----------------------- | -------------------------------------- |
| dev         | `sa.dwelleo.app.dev`    | `GoogleService-Info-dev.plist`         |
| staging     | `sa.dwelleo.app.staging`| `GoogleService-Info-staging.plist`     |
| production  | `sa.dwelleo.app`        | `GoogleService-Info-production.plist`  |

The `GoogleService-Info-*.plist` files are **gitignored** (they contain
project keys) and must be provided locally / via CI. Download each from the
matching iOS app in the Firebase console (Project settings → Your apps) and
save it here with the exact name above.

## How it is used

The Runner target's **"Copy Firebase config for flavor"** build phase copies
`GoogleService-Info-$FLAVOR.plist` into the app bundle as
`GoogleService-Info.plist`, which `FirebaseApp.configure()` reads at launch.

- **Debug** builds: if the flavor-specific file is missing, the phase falls
  back to any available plist (with a warning) so local/simulator runs are not
  blocked. The app will talk to whichever Firebase project the fallback
  belongs to until you add the correct file.
- **Release / Profile** builds: a missing flavor-specific file **fails the
  build**, so a release can never ship the wrong Firebase project.
