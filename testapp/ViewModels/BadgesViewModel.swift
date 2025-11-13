//
//  BadgesViewModel.swift
//  testapp
//
//  ViewModel for badges
//

import Foundation
import Combine

@MainActor
class BadgesViewModel: ObservableObject {
    @Published var badges: [Badge] = []
    @Published var userBadges: [UserBadge] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiClient = APIClient.shared
    
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
}

