//
//  BadgeCelebrationManager.swift
//  testapp
//
//  Manages badge celebration detection and display
//

import Foundation
import SwiftUI

@MainActor
class BadgeCelebrationManager: ObservableObject {
    static let shared = BadgeCelebrationManager()
    
    @Published var newBadge: Badge?
    @Published var showCelebration = false
    
    private var previousBadgeCodes: Set<String> = []
    
    private init() {}
    
    // Call this after actions that might earn badges (receipt upload, transaction creation, etc.)
    func checkForNewBadges() async {
        let viewModel = BadgesViewModel()
        await viewModel.loadUserBadges()
        
        let currentBadgeCodes = Set(viewModel.userBadges.map { $0.code })
        let newBadgeCodes = currentBadgeCodes.subtracting(previousBadgeCodes)
        
        if let newBadgeCode = newBadgeCodes.first {
            // Load all badges to get full badge info
            await viewModel.loadBadges()
            if let badge = viewModel.badges.first(where: { $0.code == newBadgeCode }) {
                newBadge = badge
                showCelebration = true
            }
        }
        
        previousBadgeCodes = currentBadgeCodes
    }
    
    // Call this when app launches to initialize
    func initialize() async {
        let viewModel = BadgesViewModel()
        await viewModel.loadUserBadges()
        previousBadgeCodes = Set(viewModel.userBadges.map { $0.code })
    }
    
    func dismissCelebration() {
        showCelebration = false
        newBadge = nil
    }
}

