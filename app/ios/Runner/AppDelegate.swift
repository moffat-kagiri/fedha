/// A description
import Flutter
import UIKit
import UserNotifications
import MessageUI

@main
@objc class AppDelegate: FlutterAppDelegate, UNUserNotificationCenterDelegate, MFMessageComposeViewControllerDelegate {
    
    private var smsMethodChannel: FlutterMethodChannel?
    private var notificationMethodChannel: FlutterMethodChannel?
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller = window?.rootViewController as! FlutterViewController
        
        // Setup method channels
        setupMethodChannels(controller: controller)
        
        // Request notification permissions
        UNUserNotificationCenter.current().delegate = self
        requestNotificationPermissions()
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    private func setupMethodChannels(controller: FlutterViewController) {
        // SMS Listener Channel (Limited on iOS)
        smsMethodChannel = FlutterMethodChannel(
            name: "fedha_sms_listener",
            binaryMessenger: controller.binaryMessenger
        )
        smsMethodChannel?.setMethodCallHandler(handleSmsMethodCall)
        
        // Notification Channel
        notificationMethodChannel = FlutterMethodChannel(
            name: "fedha_notifications",
            binaryMessenger: controller.binaryMessenger
        )
        notificationMethodChannel?.setMethodCallHandler(handleNotificationMethodCall)
    }
    
    // MARK: - SMS Method Handler (Limited capabilities on iOS)
    private func handleSmsMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "startSmsListener":
            startSmsListener(result: result)
        case "stopSmsListener":
            stopSmsListener(result: result)
        case "getRecentSms":
            getRecentSms(call: call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func startSmsListener(result: @escaping FlutterResult) {
        // iOS has very limited SMS access due to privacy restrictions
        result(FlutterError(
            code: "IOS_LIMITATION",
            message: "iOS does not support background SMS listening due to privacy restrictions",
            details: "Use manual SMS import or share sheet functionality instead"
        ))
    }
    
    private func stopSmsListener(result: @escaping FlutterResult) {
        result(true)
    }
    
    private func getRecentSms(call: FlutterMethodCall, result: @escaping FlutterResult) {
        // iOS doesn't allow reading SMS messages from other apps
        result(FlutterError(
            code: "IOS_LIMITATION",
            message: "iOS does not support reading SMS messages from other apps",
            details: "Use manual SMS input or share sheet functionality instead"
        ))
    }
    
    // MARK: - Notification Method Handler
    private func handleNotificationMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initializeNotifications":
            initializeNotifications(call: call, result: result)
        case "showNotification":
            showNotification(call: call, result: result)
        case "cancelNotification":
            cancelNotification(call: call, result: result)
        case "cancelAllNotifications":
            cancelAllNotifications(result: result)
        case "areNotificationsEnabled":
            areNotificationsEnabled(result: result)
        case "openNotificationSettings":
            openNotificationSettings(result: result)
        case "scheduleNotification":
            scheduleNotification(call: call, result: result)
        case "getPendingNotifications":
            getPendingNotifications(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    private func initializeNotifications(call: FlutterMethodCall, result: @escaping FlutterResult) {
        result(true)
    }
    
    private func showNotification(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let id = args["id"] as? Int,
              let title = args["title"] as? String,
              let body = args["body"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing required arguments", details: nil))
            return
        }
        
        let payload = args["payload"] as? String ?? ""
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = ["payload": payload]
        
        let request = UNNotificationRequest(
            identifier: String(id),
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            DispatchQueue.main.async {
                if let error = error {
                    result(FlutterError(code: "NOTIFICATION_ERROR", message: error.localizedDescription, details: nil))
                } else {
                    result(true)
                }
            }
        }
    }
    
    private func cancelNotification(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let id = args["id"] as? Int else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing notification ID", details: nil))
            return
        }
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [String(id)])
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [String(id)])
        result(true)
    }
    
    private func cancelAllNotifications(result: @escaping FlutterResult) {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        result(true)
    }
    
    private func areNotificationsEnabled(result: @escaping FlutterResult) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                result(settings.authorizationStatus == .authorized)
            }
        }
    }
    
    private func openNotificationSettings(result: @escaping FlutterResult) {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
            result(true)
        } else {
            result(FlutterError(code: "SETTINGS_ERROR", message: "Could not open settings", details: nil))
        }
    }
    
    private func scheduleNotification(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let id = args["id"] as? Int,
              let title = args["title"] as? String,
              let body = args["body"] as? String,
              let scheduledTime = args["scheduledTime"] as? Double else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing required arguments", details: nil))
            return
        }
        
        let payload = args["payload"] as? String ?? ""
        let scheduleDate = Date(timeIntervalSince1970: scheduledTime / 1000)
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = ["payload": payload]
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: scheduleDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: String(id),
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            DispatchQueue.main.async {
                if let error = error {
                    result(FlutterError(code: "NOTIFICATION_ERROR", message: error.localizedDescription, details: nil))
                } else {
                    result(true)
                }
            }
        }
    }
    
    private func getPendingNotifications(result: @escaping FlutterResult) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let notifications = requests.map { request in
                return [
                    "id": Int(request.identifier) ?? 0,
                    "title": request.content.title,
                    "body": request.content.body,
                    "payload": request.content.userInfo["payload"] as? String ?? ""
                ]
            }
            DispatchQueue.main.async {
                result(notifications)
            }
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let payload = response.notification.request.content.userInfo["payload"] as? String ?? ""
        
        // Send notification tap event to Flutter
        notificationMethodChannel?.invokeMethod("onNotificationTapped", arguments: payload)
        
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([.alert, .badge, .sound])
    }
    
    // MARK: - MFMessageComposeViewControllerDelegate (for manual SMS sharing)
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true)
    }
}
