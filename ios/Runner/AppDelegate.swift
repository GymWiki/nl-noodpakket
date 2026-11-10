import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  // Documentenkluis: verberg de inhoud in de app-switcher en bij schermopname.
  private var secureEnabled = false
  private var overlay: UIView?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate

    if let registrar = self.registrar(forPlugin: "NoodpakketSecure") {
      let channel = FlutterMethodChannel(
        name: "nl.mijnnoodpakket/secure",
        binaryMessenger: registrar.messenger()
      )
      channel.setMethodCallHandler { [weak self] call, result in
        switch call.method {
        case "setSecure":
          self?.secureEnabled = (call.arguments as? Bool) ?? false
          self?.updateOverlay()
          result(nil)
        case "excludeFromBackup":
          if let path = call.arguments as? String {
            var url = URL(fileURLWithPath: path)
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            try? url.setResourceValues(values)
          }
          result(nil)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    let nc = NotificationCenter.default
    nc.addObserver(self, selector: #selector(updateOverlay),
                   name: UIApplication.willResignActiveNotification, object: nil)
    nc.addObserver(self, selector: #selector(updateOverlay),
                   name: UIApplication.didBecomeActiveNotification, object: nil)
    nc.addObserver(self, selector: #selector(updateOverlay),
                   name: UIScreen.capturedDidChangeNotification, object: nil)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// Toont een dekkende laag als de kluis open staat en de app niet actief is
  /// (app-switcher) of het scherm wordt opgenomen.
  @objc private func updateOverlay() {
    let inactive = UIApplication.shared.applicationState != .active
    let capturing = UIScreen.main.isCaptured
    let show = secureEnabled && (inactive || capturing)
    guard let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow })
      ?? UIApplication.shared.windows.first else { return }
    if show {
      if overlay == nil {
        let v = UIView(frame: window.bounds)
        v.backgroundColor = UIColor.systemBackground
        v.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        window.addSubview(v)
        overlay = v
      }
    } else {
      overlay?.removeFromSuperview()
      overlay = nil
    }
  }
}
