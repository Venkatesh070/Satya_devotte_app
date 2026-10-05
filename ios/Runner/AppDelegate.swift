import Flutter
import FirebaseMessaging
import UIKit
import UserNotifications
import FirebaseCore
import EventKit
import EventKitUI

class CalendarHandler: NSObject, EKEventEditViewDelegate {
  static let shared = CalendarHandler()
  let eventStore = EKEventStore()
  var pendingResult: FlutterResult?

  func addEvent(
    title: String,
    description: String,
    location: String,
    startDate: Date,
    endDate: Date,
    allDay: Bool,
    result: @escaping FlutterResult
  ) {
    print("[iOS Calendar] addEvent requested: title='\(title)', start=\(startDate), end=\(endDate), allDay=\(allDay)")
    self.pendingResult = result

    let performAdd = {
      DispatchQueue.main.async {
        let event = EKEvent(eventStore: self.eventStore)
        event.title = title
        event.notes = description
        event.location = location
        event.startDate = startDate
        event.endDate = endDate > startDate ? endDate : startDate.addingTimeInterval(86400)
        event.isAllDay = allDay
        event.calendar = self.eventStore.defaultCalendarForNewEvents

        let editController = EKEventEditViewController()
        editController.eventStore = self.eventStore
        editController.event = event
        editController.editViewDelegate = self
        editController.modalPresentationStyle = .pageSheet

        guard let windowScene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first(where: { $0.activationState == .foregroundActive || $0.activationState == .foregroundInactive }) ?? UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first,
              let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }) ?? windowScene.windows.first,
              let rootVC = keyWindow.rootViewController else {
          print("[iOS Calendar] ERROR: Could not find keyWindow or rootViewController!")
          result(false)
          return
        }

        var topVC = rootVC
        while let presented = topVC.presentedViewController, !presented.isBeingDismissed {
          topVC = presented
        }

        print("[iOS Calendar] Presenting EKEventEditViewController on \(type(of: topVC))...")
        topVC.present(editController, animated: true) {
          print("[iOS Calendar] EKEventEditViewController presentation completed successfully.")
        }
      }
    }

    if #available(iOS 17.0, *) {
      print("[iOS Calendar] Requesting full access to events (iOS 17+)...")
      eventStore.requestFullAccessToEvents { granted, error in
        print("[iOS Calendar] Permission response: granted=\(granted), error=\(String(describing: error))")
        if granted && error == nil {
          performAdd()
        } else {
          DispatchQueue.main.async { result(false) }
        }
      }
    } else {
      print("[iOS Calendar] Requesting access to events (iOS <17)...")
      eventStore.requestAccess(to: .event) { granted, error in
        print("[iOS Calendar] Permission response: granted=\(granted), error=\(String(describing: error))")
        if granted && error == nil {
          performAdd()
        } else {
          DispatchQueue.main.async { result(false) }
        }
      }
    }
  }

  func eventEditViewController(
    _ controller: EKEventEditViewController,
    didCompleteWith action: EKEventEditViewAction
  ) {
    let actionName: String
    switch action {
    case .saved: actionName = "saved"
    case .canceled: actionName = "canceled"
    case .deleted: actionName = "deleted"
    @unknown default: actionName = "unknown"
    }
    print("[iOS Calendar] eventEditViewController didCompleteWith action: \(actionName)")

    controller.dismiss(animated: true) { [weak self] in
      print("[iOS Calendar] EKEventEditViewController dismissed, returning result to Flutter: \(action == .saved)")
      let success = (action == .saved)
      self?.pendingResult?(success)
      self?.pendingResult = nil
    }
  }
}

class NativeCalendarPlugin: NSObject, FlutterPlugin {
  static func register(with registrar: FlutterPluginRegistrar) {
    print("[iOS Calendar] NativeCalendarPlugin registered on method channel 'com.sathya.app/calendar'")
    let channel = FlutterMethodChannel(
      name: "com.sathya.app/calendar",
      binaryMessenger: registrar.messenger()
    )
    let instance = NativeCalendarPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    print("[iOS Calendar] NativeCalendarPlugin handle: method='\(call.method)'")
    if call.method == "addEvent", let args = call.arguments as? [String: Any] {
      let title = args["title"] as? String ?? ""
      let desc = args["description"] as? String ?? ""
      let loc = args["location"] as? String ?? ""
      let startMs = args["startDate"] as? Double ?? Double(args["startDate"] as? Int64 ?? 0)
      let endMs = args["endDate"] as? Double ?? Double(args["endDate"] as? Int64 ?? 0)
      let allDay = args["allDay"] as? Bool ?? true

      let start = Date(timeIntervalSince1970: startMs / 1000.0)
      let end = Date(timeIntervalSince1970: endMs / 1000.0)

      CalendarHandler.shared.addEvent(
        title: title,
        description: desc,
        location: loc,
        startDate: start,
        endDate: end,
        allDay: allDay,
        result: result
      )
    } else {
      result(FlutterMethodNotImplemented)
    }
  }
}

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if FirebaseApp.app() == nil {
      FirebaseApp.configure()
    }
    UNUserNotificationCenter.current().delegate = self
    application.registerForRemoteNotifications()

    if !self.hasPlugin("NativeCalendarPlugin"), let registrar = self.registrar(forPlugin: "NativeCalendarPlugin") {
      NativeCalendarPlugin.register(with: registrar)
    }

    return super.application(
      application,
      didFinishLaunchingWithOptions: launchOptions
    )
  }

  // Remote pushes always show as a banner in the foreground; super still runs so
  // firebase_messaging delivers Dart onMessage. Local notifications are left to
  // flutter_local_notifications via super.
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    guard notification.request.trigger is UNPushNotificationTrigger else {
      super.userNotificationCenter(center, willPresent: notification, withCompletionHandler: completionHandler)
      return
    }

    let options: UNNotificationPresentationOptions
    if #available(iOS 14.0, *) {
      options = [.banner, .list, .sound, .badge]
    } else {
      options = [.alert, .sound, .badge]
    }
    var completed = false
    let finish: (UNNotificationPresentationOptions) -> Void = { _ in
      DispatchQueue.main.async {
        guard !completed else { return }
        completed = true
        completionHandler(options)
      }
    }
    super.userNotificationCenter(center, willPresent: notification, withCompletionHandler: finish)
    // Plugins may not call back at all; never leave the banner pending.
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { finish(options) }
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    super.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    Messaging.messaging().apnsToken = deviceToken
    let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    print("[FCM][iOS] APNs token set: \(token.prefix(20))...")
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    print("[FCM][iOS] APNs registration failed: \(error.localizedDescription)")
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if !engineBridge.pluginRegistry.hasPlugin("NativeCalendarPlugin"),
       let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "NativeCalendarPlugin") {
      NativeCalendarPlugin.register(with: registrar)
    }
  }
}