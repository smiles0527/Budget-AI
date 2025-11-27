//
//  PushNotificationService.swift
//  testapp
//
//  Push notification service for APNs integration
//

import Foundation
import UserNotifications
import UIKit

@MainActor
class PushNotificationService: NSObject, ObservableObject {
    static let shared = PushNotificationService()
    
    @Published var isRegistered = false
    @Published var deviceToken: String?
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var pendingNavigation: NavigationDestination?

    enum NavigationDestination: Identifiable {
        case budgetAlert
        case goalDetails(String)
        case streak
        case receipt(String)
        
        var id: String {
            switch self {
            case .budgetAlert: return "budget"
            case .goalDetails(let id): return "goal-\(id)"
            case .streak: return "streak"
            case .receipt(let id): return "receipt-\(id)"
            }
        }
    }
    
    private let apiClient = APIClient.shared
    
    override private init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            await updateAuthorizationStatus()
            return granted
        } catch {
            print("Error requesting notification authorization: \(error)")
            return false
        }
    }
    
    func updateAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }
    
    func registerForPushNotifications() {
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    func didRegisterForRemoteNotifications(deviceToken: Data) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        self.deviceToken = token
        
        Task {
            await registerDevice(token: token)
        }
    }
    
    func didFailToRegisterForRemoteNotifications(error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }
    
    private func registerDevice(token: String) async {
        do {
            try await apiClient.registerPushDevice(platform: "apns", token: token)
            isRegistered = true
            print("Successfully registered device for push notifications")
        } catch {
            print("Error registering device: \(error)")
            isRegistered = false
        }
    }
    
    func unregisterDevice() async {
        guard let token = deviceToken else { return }
        
        do {
            // Get list of devices and delete this one
            let devices = try await apiClient.getPushDevices()
            if let device = devices.items.first(where: { $0.token == token }) {
                try await apiClient.deletePushDevice(deviceId: device.id)
                isRegistered = false
                deviceToken = nil
            }
        } catch {
            print("Error unregistering device: \(error)")
        }
    }
    
    func handleNotification(userInfo: [AnyHashable: Any]) {
        // Handle different notification types
        guard let notificationType = userInfo["type"] as? String else { return }
        
        switch notificationType {
        case "budget_alert":
            handleBudgetAlert(userInfo: userInfo)
        case "goal_achieved":
            handleGoalAchieved(userInfo: userInfo)
        case "streak_reminder":
            handleStreakReminder(userInfo: userInfo)
        case "receipt_processed":
            handleReceiptProcessed(userInfo: userInfo)
        default:
            print("Unknown notification type: \(notificationType)")
        }
    }
    
    private func handleBudgetAlert(userInfo: [AnyHashable: Any]) {
        // Budget alert notifications
        print("Budget alert notification received")
        pendingNavigation = .budgetAlert
    }
    
    private func handleGoalAchieved(userInfo: [AnyHashable: Any]) {
        // Goal achievement notifications
        print("Goal achieved notification received")
        if let goalId = userInfo["goal_id"] as? String {
            pendingNavigation = .goalDetails(goalId)
        }
    }
    
    private func handleStreakReminder(userInfo: [AnyHashable: Any]) {
        // Streak reminder notifications
        print("Streak reminder notification received")
        pendingNavigation = .streak
    }
    
    private func handleReceiptProcessed(userInfo: [AnyHashable: Any]) {
        // Receipt processing complete notifications
        print("Receipt processed notification received")
        if let receiptId = userInfo["receipt_id"] as? String {
            pendingNavigation = .receipt(receiptId)
        }
    }
}

extension PushNotificationService: UNUserNotificationCenterDelegate {
    // Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
        
        // Handle notification data
        handleNotification(userInfo: notification.request.content.userInfo)
    }
    
    // Handle notification tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        handleNotification(userInfo: response.notification.request.content.userInfo)
        completionHandler()
    }
}

