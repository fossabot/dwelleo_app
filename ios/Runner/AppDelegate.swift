#if canImport(FirebaseCore)
import FirebaseCore
#endif
import Flutter
#if canImport(GoogleMaps)
import GoogleMaps
#endif
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
#if canImport(FirebaseCore)
    FirebaseApp.configure()
#else
    // FirebaseCore not available; skip configuration to allow build without Firebase.
#endif
    // Google Maps native SDK key (iOS). Read from Info.plist ($(MAPS_API_KEY)),
    // which is populated by the GITIGNORED ios/Flutter/Secrets.xcconfig — the key
    // is NEVER hardcoded/committed. Restrict it to the app's bundle IDs.
#if canImport(GoogleMaps)
    // Only a real Google key (starts with "AIza") is used; placeholders like
    // "PASTE_…" or "<new iOS key>" are skipped so the map fails cleanly.
    if let mapsKey = Bundle.main.object(forInfoDictionaryKey: "MapsApiKey") as? String,
       mapsKey.hasPrefix("AIza") {
      GMSServices.provideAPIKey(mapsKey)
    }
#else
    // GoogleMaps not available; skip API key configuration to allow build without Google Maps.
#endif
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}

