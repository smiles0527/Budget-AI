//
//  SavingsGoalsViewModel.swift
//  testapp
//
//  ViewModel for savings goals
//

import Foundation
import Combine

@MainActor
class SavingsGoalsViewModel: ObservableObject {
    @Published var goals: [SavingsGoal] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiClient = APIClient.shared
    
    func loadGoals(status: String? = nil) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiClient.getSavingsGoals(status: status)
            goals = response.items
        } catch {
            errorMessage = ErrorHandler.userFriendlyMessage(for: error)
        }
        
        isLoading = false
    }
    
    func createGoal(
        name: String,
        category: String?,
        targetCents: Int,
        startDate: String?,
        targetDate: String?
    ) async {
        isLoading = true
        errorMessage = nil
        
        do {
            _ = try await apiClient.createSavingsGoal(
                name: name,
                category: category,
                targetCents: targetCents,
                startDate: startDate,
                targetDate: targetDate
            )
            await loadGoals()
        } catch {
            errorMessage = ErrorHandler.userFriendlyMessage(for: error)
        }
        
        isLoading = false
    }
    
    func addContribution(goalId: String, amountCents: Int, note: String?) async {
        isLoading = true
        errorMessage = nil
        
        do {
            _ = try await apiClient.addContribution(
                goalId: goalId,
                amountCents: amountCents,
                note: note
            )
            await loadGoals()
        } catch {
            errorMessage = ErrorHandler.userFriendlyMessage(for: error)
        }
        
        isLoading = false
    }
    
    func formatAmount(cents: Int) -> String {
        return CurrencyFormatter.shared.format(cents: cents)
    }
    
    func progressPercentage(goal: SavingsGoal) -> Double {
        guard let contributed = goal.contributed_cents, goal.target_cents > 0 else {
            return 0
        }
        return min(100.0, (Double(contributed) / Double(goal.target_cents)) * 100.0)
    }
    
    func getGoal(id: String) async -> SavingsGoal? {
        isLoading = true
        errorMessage = nil
        
        do {
            let goal = try await apiClient.getSavingsGoal(id: id)
            isLoading = false
            return goal
        } catch {
            errorMessage = ErrorHandler.userFriendlyMessage(for: error)
            isLoading = false
            return nil
        }
    }
    
    func updateGoal(
        id: String,
        name: String? = nil,
        category: String? = nil,
        targetCents: Int? = nil,
        targetDate: String? = nil,
        status: String? = nil
    ) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await apiClient.updateSavingsGoal(
                id: id,
                name: name,
                category: category,
                targetCents: targetCents,
                targetDate: targetDate,
                status: status
            )
            await loadGoals()
        } catch {
            errorMessage = ErrorHandler.userFriendlyMessage(for: error)
        }
        
        isLoading = false
    }
    
    func deleteGoal(id: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await apiClient.deleteSavingsGoal(id: id)
            await loadGoals()
        } catch {
            errorMessage = ErrorHandler.userFriendlyMessage(for: error)
        }
        
        isLoading = false
    }
}

