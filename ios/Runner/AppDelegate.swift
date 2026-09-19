import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var privacyBlurView: UIVisualEffectView?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func applicationWillResignActive(_ application: UIApplication) {
    super.applicationWillResignActive(application)
    if privacyBlurView == nil, let window = self.window {
      let blur = UIBlurEffect(style: .dark)
      let view = UIVisualEffectView(effect: blur)
      view.frame = window.bounds
      view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      view.tag = 9999
      window.addSubview(view)
      self.privacyBlurView = view
    }
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    self.privacyBlurView?.removeFromSuperview()
    self.privacyBlurView = nil
  }
}
