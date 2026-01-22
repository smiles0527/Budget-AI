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
    @Published var budgets: [BudgetWithSpending] = []
    @Published var alerts: [BudgetAlert] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiClient = APIClient.shared
    
    func loadBudgets(periodStart: String? = nil, periodEnd: String? = nil) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiClient.getBudgets(periodStart: periodStart, periodEnd: periodEnd)
            // Load spending data for each budget
            var budgetsWithSpending: [BudgetWithSpending] = []
            for budget in response.items {
                let spending = await getSpendingForBudget(budget: budget)
                budgetsWithSpending.append(BudgetWithSpending(budget: budget, spentCents: spending))
            }
            budgets = budgetsWithSpending
        } catch {
            errorMessage = ErrorHandler.userFriendlyMessage(for: error)
        }
        
        isLoading = false
    }
    
    private func getSpendingForBudget(budget: Budget) async -> Int {
        do {
            let response = try await apiClient.getTransactions(
                limit: 1000,
                fromDate: budget.period_start,
                toDate: budget.period_end,
                category: budget.category
            )
            return response.items.reduce(0) { $0 + $1.total_cents }
        } catch {
            return 0
        }
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
            errorMessage = ErrorHandler.userFriendlyMessage(for: error)
        }
        
        isLoading = false
    }
    
    func updateBudget(budgetId: String, periodStart: String, periodEnd: String, category: String, limitCents: Int) async {
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
            errorMessage = ErrorHandler.userFriendlyMessage(for: error)
        }
        
        isLoading = false
    }
    
    func formatAmount(cents: Int) -> String {
        return CurrencyFormatter.shared.format(cents: cents)
    }
    
    func getProgressPercentage(budget: BudgetWithSpending) -> Double {
        guard budget.budget.limit_cents > 0 else { return 0 }
        return min(Double(budget.spentCents) / Double(budget.budget.limit_cents), 1.0)
    }
}

struct BudgetWithSpending: Identifiable {
    var id: String { budget.id }
    let budget: Budget
    let spentCents: Int
}

