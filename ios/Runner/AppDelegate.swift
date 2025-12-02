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
    GMSServices.provideAPIKey("AIzaSyCr3d9xsVRaS_2njjo2ZG1dj0lKD94smUg")
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}