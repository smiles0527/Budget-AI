//
//  UsageViewModel.swift
//  testapp
//
//  ViewModel for usage statistics
//

import Foundation
import Combine

@MainActor
class UsageViewModel: ObservableObject {
    @Published var usage: UsageResponse?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiClient = APIClient.shared
    
    func loadUsage() async {
        isLoading = true
        errorMessage = nil
        
        do {
            usage = try await apiClient.getUsage()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

