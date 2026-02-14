import Flutter
import GoogleMaps
import MapKit
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override var window: UIWindow? {
    get { super.window }
    set { super.window = newValue }
  }

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

    // Explicitly create a Flutter root controller to avoid storyboard/scene
    // startup inconsistencies that can lead to a blank screen.
    let flutterController = FlutterViewController(project: nil, nibName: nil, bundle: nil)
    window = UIWindow(frame: UIScreen.main.bounds)
    window?.rootViewController = flutterController
    window?.makeKeyAndVisible()

    GeneratedPluginRegistrant.register(with: flutterController)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
