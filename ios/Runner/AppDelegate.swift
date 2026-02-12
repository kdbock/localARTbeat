import Flutter
import GoogleMaps
import MapKit
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Initialize Google Maps by reading API key from Info.plist
    if let path = Bundle.main.path(forResource: "Info", ofType: "plist"),
      let plist = NSDictionary(contentsOfFile: path),
      let apiKey = plist["GMSApiKey"] as? String
    {
      print("Google Maps API Key found: \(String(apiKey.prefix(10)))...")
      GMSServices.provideAPIKey(apiKey)
    } else {
      print("ERROR: Google Maps API Key not found in Info.plist")
      // Fallback to hardcoded key
      GMSServices.provideAPIKey("AIzaSyBvmSCvenoo9u-eXNzKm_oDJJJjC0MbqHA")
    }

    GeneratedPluginRegistrant.register(with: self)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // MARK: UISceneSession Lifecycle

  override func application(
    _ application: UIApplication,
    configurationForConnecting connectingSceneSession: UISceneSession,
    options: UIScene.ConnectionOptions
  ) -> UISceneConfiguration {
    return UISceneConfiguration(
      name: "Default Configuration", sessionRole: connectingSceneSession.role)
  }

  override func application(
    _ application: UIApplication,
    didDiscardSceneSessions sceneSessions: Set<UISceneSession>
  ) {
    // Called when the user discards a scene session.
  }
}
