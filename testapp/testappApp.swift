//
//  testappApp.swift
//  testapp
//
//  Created by Curtis Wei on 2025-08-24.
//

import SwiftUI

@main
struct testappApp: App {
    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(AuthManager.shared)
        }
    }
}

