//
//  PremiumGate.swift
//  testapp
//
//  Utility for premium feature gating
//

import SwiftUI

class PremiumGate {
    static func isPremium() -> Bool {
        let authManager = AuthManager.shared
        return authManager.subscription?.plan == "premium" && 
               authManager.subscription?.status == "active"
    }
    
    static func requirePremium(action: @escaping () -> Void, onUpgrade: @escaping () -> Void) {
        if isPremium() {
            action()
        } else {
            onUpgrade()
        }
    }
}

struct PremiumGateView<Content: View, LockedContent: View>: View {
    @StateObject private var authManager = AuthManager.shared
    @State private var showingUpgrade = false
    
    let content: Content
    let lockedContent: LockedContent
    
    init(@ViewBuilder content: () -> Content, @ViewBuilder lockedContent: () -> LockedContent) {
        self.content = content()
        self.lockedContent = lockedContent()
    }
    
    var isPremium: Bool {
        authManager.subscription?.plan == "premium" && 
        authManager.subscription?.status == "active"
    }
    
    var body: some View {
        if isPremium {
            content
        } else {
            lockedContent
                .onTapGesture {
                    showingUpgrade = true
                }
                .sheet(isPresented: $showingUpgrade) {
                    UpgradeView()
                }
        }
    }
}

struct PremiumLockedView: View {
    let featureName: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "lock.fill")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            
            Text("Premium Feature")
                .font(.headline)
            
            Text("\(featureName) is available for Premium users")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: {}) {
                Text("Upgrade to Premium")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .cornerRadius(20)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

