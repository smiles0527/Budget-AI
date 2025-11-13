//
//  BudgetsViewModel.swift
//  testapp
//
//  ViewModel for budgets management
//

import Foundation
import Combine

@MainActor
class BudgetsViewModel: ObservableObject {
    @Published var budgets: [Budget] = []
    @Published var alerts: [BudgetAlert] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiClient = APIClient.shared
    
    func loadBudgets(periodStart: String? = nil, periodEnd: String? = nil) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiClient.getBudgets(periodStart: periodStart, periodEnd: periodEnd)
            budgets = response.items
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func createBudget(periodStart: String, periodEnd: String, category: String, limitCents: Int) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await apiClient.createBudget(
                periodStart: periodStart,
                periodEnd: periodEnd,
                category: category,
                limitCents: limitCents
            )
            await loadBudgets()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func formatAmount(cents: Int) -> String {
        let dollars = Double(cents) / 100.0
        return String(format: "$%.2f", dollars)
    }
}

struct BudgetAlert: Codable {
    let id: String
    let alert_type: String
    let category: String?
    let message: String
    let status: String
    let threshold_cents: Int?
    let current_cents: Int?
    let created_at: String
}

