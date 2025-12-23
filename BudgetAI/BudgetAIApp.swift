//
//  testappApp.swift
//  testapp
//
//  Created by Curtis Wei on 2025-08-24.
//

import SwiftUI
import UserNotifications

@main
struct BudgetAIApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(AuthManager.shared)
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        // Request notification permissions on app launch
        Task {
            await PushNotificationService.shared.requestAuthorization()
            PushNotificationService.shared.registerForPushNotifications()
        }
        return true
    }
    
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        PushNotificationService.shared.didRegisterForRemoteNotifications(deviceToken: deviceToken)
    }
    
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        PushNotificationService.shared.didFailToRegisterForRemoteNotifications(error: error)
    }
    
    // Handle remote notification when app is launched from notification
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable : Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        PushNotificationService.shared.handleNotification(userInfo: userInfo)
        completionHandler(.newData)
    }
}

