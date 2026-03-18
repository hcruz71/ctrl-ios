import Foundation
import UIKit
import UserNotifications
import os.log

private let logger = Logger(subsystem: "com.hector.ctrl", category: "PushManager")

/// Handles APNs registration, permission requests, and device token management.
@MainActor
final class PushManager: NSObject, ObservableObject {
    static let shared = PushManager()

    @Published var deviceToken: String?
    @Published var permissionStatus: UNAuthorizationStatus = .notDetermined

    /// Whether the current `deviceToken` has been successfully sent to the backend.
    private var tokenSentToBackend = false

    private override init() {
        super.init()
        Task { await refreshPermissionStatus() }
    }

    /// Check current permission status (updates `permissionStatus`).
    func refreshPermissionStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        permissionStatus = settings.authorizationStatus
        logger.info("Push permission status: \(String(describing: settings.authorizationStatus.rawValue))")
    }

    /// Request notification permission and register for remote notifications.
    func requestPermissionAndRegister() async {
        logger.info("requestPermissionAndRegister() called")

        // If we already have a token that wasn't sent, retry before re-registering.
        if let existing = deviceToken, !tokenSentToBackend {
            logger.info("Retrying backend registration with existing token")
            await sendTokenToBackend(existing)
            return
        }

        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])

            await refreshPermissionStatus()

            guard granted else {
                logger.warning("User denied push permission")
                return
            }

            logger.info("Calling registerForRemoteNotifications()")
            UIApplication.shared.registerForRemoteNotifications()
        } catch {
            logger.error("Permission request error: \(error.localizedDescription)")
        }
    }

    /// Called from AppDelegate when APNs returns the device token.
    func didRegisterForRemoteNotifications(token: Data) {
        let tokenString = token.map { String(format: "%02.2hhx", $0) }.joined()
        logger.info("APNs token received: \(tokenString.prefix(16))…")
        tokenSentToBackend = false
        deviceToken = tokenString
        Task { await sendTokenToBackend(tokenString) }
    }

    /// Called from AppDelegate when APNs registration fails.
    func didFailToRegisterForRemoteNotifications(error: Error) {
        logger.error("APNs registration failed: \(error.localizedDescription)")
    }

    /// Send device token to the backend via POST.
    private func sendTokenToBackend(_ token: String) async {
        guard AuthManager.shared.token != nil else {
            logger.warning("No auth token — skipping backend registration")
            return
        }

        logger.info("Sending device token to backend…")
        let body = RegisterTokenBody(token: token, platform: "ios")

        do {
            let _: EmptyData? = try await APIClient.shared.request(.registerToken, body: body)
            tokenSentToBackend = true
            logger.info("Device token sent to backend ✓")
        } catch {
            tokenSentToBackend = false
            logger.error("Failed to send device token to backend: \(error.localizedDescription)")
        }
    }
}

// MARK: - Request body

private struct RegisterTokenBody: Encodable {
    let token: String
    let platform: String
}
