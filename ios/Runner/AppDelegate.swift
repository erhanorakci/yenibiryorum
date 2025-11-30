import Flutter
import UIKit
import GoogleMaps // 1. Bu satır eklendi

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // 2. API Anahtarı buraya eklendi
    GMSServices.provideAPIKey("AIzaSyCT18QMZpO-RohkM4hp1tbVhTCJl4j1g_U")
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}