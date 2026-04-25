import Flutter
import UIKit
// import GoogleMaps  // Removed for v1

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Google Maps removed for v1
    // GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY_HERE")

    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      InstagramSharePlugin.register(messenger: controller.binaryMessenger)
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

/// Instagram Stories share handler.
///
/// Native side of the `com.fitwiz/instagram_share` MethodChannel. Stages the
/// captured workout image on `UIPasteboard` using Instagram's documented
/// sticker key, then opens `instagram-stories://share?source_application=...`
/// so Instagram pulls the image straight into the Stories composer instead of
/// just landing the user on the main feed.
class InstagramSharePlugin: NSObject {
  private static let channelName = "com.fitwiz/instagram_share"
  // Must match the iOS bundle ID registered in Xcode (project.pbxproj).
  private static let sourceApplication = "com.aifitnesscoach.aiFitnessCoach"

  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
    let instance = InstagramSharePlugin()
    channel.setMethodCallHandler { call, result in
      instance.handle(call, result: result)
    }
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "shareToInstagramStories":
      shareToInstagramStories(call: call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func shareToInstagramStories(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let imagePath = args["imagePath"] as? String else {
      result(FlutterError(code: "INVALID_ARGUMENTS",
                          message: "imagePath required",
                          details: nil))
      return
    }

    guard let imageData = try? Data(contentsOf: URL(fileURLWithPath: imagePath)) else {
      result(FlutterError(code: "READ_FAILED",
                          message: "Could not read image at \(imagePath)",
                          details: nil))
      return
    }

    let urlString = "instagram-stories://share?source_application=\(InstagramSharePlugin.sourceApplication)"
    guard let storyURL = URL(string: urlString),
          UIApplication.shared.canOpenURL(storyURL) else {
      result(false)
      return
    }

    let pasteboardItems: [[String: Any]] = [[
      "com.instagram.sharedSticker.backgroundImage": imageData
    ]]
    let pasteboardOptions: [UIPasteboard.OptionsKey: Any] = [
      .expirationDate: Date(timeIntervalSinceNow: 60 * 5)
    ]
    UIPasteboard.general.setItems(pasteboardItems, options: pasteboardOptions)

    UIApplication.shared.open(storyURL, options: [:]) { success in
      result(success)
    }
  }
}
