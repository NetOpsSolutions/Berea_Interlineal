import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    setupMethodChannel()
    return result
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  private func setupMethodChannel() {
    guard let controller = window?.rootViewController as? FlutterViewController else { return }
    let channel = FlutterMethodChannel(
      name: "com.example.logos_k_logos/updater",
      binaryMessenger: controller.binaryMessenger
    )

    channel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      switch call.method {
      case "openUrl":
        guard let args = call.arguments as? [String: Any],
              let urlString = args["url"] as? String,
              let url = URL(string: urlString) else {
          result(FlutterError(code: "INVALID_URL", message: "URL no válida", details: nil))
          return
        }
        UIApplication.shared.open(url, options: [:]) { success in
          result(success)
        }
      case "getDeviceArchitecture":
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
          guard let value = element.value as? Int8, value != 0 else { return identifier }
          return identifier + String(UnicodeScalar(UInt8(value)))
        }
        result([
          "primaryAbi": "arm64",
          "supportedAbis": ["arm64"],
          "manufacturer": "Apple",
          "model": identifier.isEmpty ? UIDevice.current.model : identifier,
          "sdkInt": 0
        ])
      case "getAppVersion":
        let versionName = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.3.2"
        let versionCode = Int(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "6") ?? 6
        result([
          "versionName": versionName,
          "versionCode": versionCode
        ])
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
