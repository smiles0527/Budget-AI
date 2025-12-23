//
//  AuthManager.swift
//  testapp
//
//  Authentication state management
//

import Foundation
import Combine

class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var subscription: Subscription?
    
    private let apiClient = APIClient.shared
    private let tokenKey = "auth_token"
    
    private init() {
        loadStoredToken()
    }
    
    private func loadStoredToken() {
        if let token = UserDefaults.standard.string(forKey: tokenKey) {
            apiClient.setAuthToken(token)
            Task {
                await refreshUser()
            }
        }
    }
    
    func login(email: String, password: String) async throws {
        let response = try await apiClient.login(email: email, password: password)
        UserDefaults.standard.set(response.token, forKey: tokenKey)
        await refreshUser()
    }
    
    func signup(email: String, password: String) async throws {
        _ = try await apiClient.signup(email: email, password: password)
        try await login(email: email, password: password)
    }
    
    func loginWithGoogle(idToken: String) async throws {
        let response = try await apiClient.loginWithGoogle(idToken: idToken)
        UserDefaults.standard.set(response.token, forKey: tokenKey)
        await refreshUser()
    }
    
    func loginWithApple(identityToken: String) async throws {
        let response = try await apiClient.loginWithApple(identityToken: identityToken)
        UserDefaults.standard.set(response.token, forKey: tokenKey)
        await refreshUser()
    }
    
    func logout() async throws {
        try await apiClient.logout()
        UserDefaults.standard.removeObject(forKey: tokenKey)
        isAuthenticated = false
        currentUser = nil
        subscription = nil
    }
    
    @MainActor
    private func refreshUser() async {
        do {
            let response = try await apiClient.getCurrentUser()
            currentUser = response.user
            subscription = response.subscription
            isAuthenticated = true
        } catch {
            isAuthenticated = false
            currentUser = nil
            subscription = nil
        }
    }
}

