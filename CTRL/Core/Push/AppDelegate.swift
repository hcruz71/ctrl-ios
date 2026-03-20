import UIKit
import UserNotifications
import os.log

private let logger = Logger(subsystem: "com.hector.ctrl", category: "AppDelegate")

/// UIApplicationDelegate that bridges APNs callbacks into SwiftUI.
/// Also acts as UNUserNotificationCenterDelegate for foreground + tap handling.
final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        logger.info("didFinishLaunchingWithOptions — setting UNUserNotificationCenter delegate")
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // MARK: - APNs token

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let hex = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        logger.info("didRegisterForRemoteNotificationsWithDeviceToken: \(hex.prefix(16))…")
        Task { @MainActor in
            PushManager.shared.didRegisterForRemoteNotifications(token: deviceToken)
        }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        logger.error("didFailToRegisterForRemoteNotificationsWithError: \(error.localizedDescription)")
        Task { @MainActor in
            PushManager.shared.didFailToRegisterForRemoteNotifications(error: error)
        }
    }

    // MARK: - Foreground notification display

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        logger.info("willPresent notification in foreground: \(notification.request.content.title)")
        completionHandler([.banner, .sound, .badge])
    }

    // MARK: - Notification tap handler

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        logger.info("Notification tapped — userInfo: \(userInfo)")

        if let type = userInfo["type"] as? String {
            Task { @MainActor in
                switch type {
                case "delegation:overdue":
                    NavigationState.shared.selectedTab = 4
                case "meeting:upcoming":
                    NavigationState.shared.selectedTab = 1
                case "task:overdue":
                    NavigationState.shared.selectedTab = 3
                default:
                    break
                }
            }
        }

        completionHandler()
    }
}
