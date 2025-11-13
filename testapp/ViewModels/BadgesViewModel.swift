//
//  BadgesViewModel.swift
//  testapp
//
//  ViewModel for badges
//

import Foundation
import Combine

struct BadgeInfo {
    let badge: Badge
    let isEarned: Bool
    let awardedAt: String?
}

@MainActor
class BadgesViewModel: ObservableObject {
    @Published var badges: [Badge] = []
    @Published var userBadges: [UserBadge] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiClient = APIClient.shared
    
    // Computed property that combines all badges with earned status
    var allBadges: [BadgeInfo] {
        let earnedCodes = Set(userBadges.map { $0.code })
        return badges.map { badge in
            let userBadge = userBadges.first { $0.code == badge.code }
            return BadgeInfo(
                badge: badge,
                isEarned: earnedCodes.contains(badge.code),
                awardedAt: userBadge?.awarded_at
            )
        }
    }
    
    func loadBadges() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiClient.getBadges()
            badges = response.items
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func loadUserBadges() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiClient.getUserBadges()
            userBadges = response.items
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // Load both badges and user badges
    func loadAllBadges() async {
        isLoading = true
        errorMessage = nil
        
        async let badgesTask = loadBadges()
        async let userBadgesTask = loadUserBadges()
        
        await badgesTask
        await userBadgesTask
        
        isLoading = false
    }
    
    // Check if a badge is earned
    func isEarned(badgeCode: String) -> Bool {
        return userBadges.contains { $0.code == badgeCode }
    }
    
    // Get earned count
    var earnedCount: Int {
        return userBadges.count
    }
    
    // Get total count
    var totalCount: Int {
        return badges.count
    }
}

