//
//  DashboardViewModel.swift
//  BudgetAI
//
//  ViewModel for dashboard data
//

import Foundation
import Combine

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var summary: DashboardSummary?
    @Published var categories: [CategorySpending] = []
    @Published var recentTransactions: [Transaction] = []
    @Published var userBadges: [UserBadge] = []
    @Published var budgets: [Budget] = []
    @Published var usage: UsageResponse?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    @Published var spendingTrends: SpendingTrendsResponse?
    @Published var forecast: SpendingForecastResponse?
    @Published var insights: [Insight] = []
    
    private let apiClient = APIClient.shared
    
    // Computed: Total budget limit from all active budgets
    var totalBudgetLimit: Int {
        budgets.reduce(0) { $0 + $1.limit_cents }
    }
    
    // Computed: Budget health percentage (0-1)
    var budgetHealthProgress: Double {
        guard totalBudgetLimit > 0, let spend = summary?.total_spend_cents else { return 1.0 }
        let remaining = Double(totalBudgetLimit - spend) / Double(totalBudgetLimit)
        return min(1.0, max(0.0, remaining))
    }
    
    // Computed XP/Level based on badges earned and transactions logged
    var userLevel: Int {
        // Each badge = 100 XP, every 10 transactions = 50 XP
        // Level = XP / 500
        let badgeXP = userBadges.count * 100
        let txnXP = (recentTransactions.count / 10) * 50
        let totalXP = badgeXP + txnXP + 100 // Start with 100 base XP
        return max(1, totalXP / 500 + 1)
    }
    
    var currentXP: Int {
        let badgeXP = userBadges.count * 100
        let txnXP = (recentTransactions.count / 10) * 50
        return badgeXP + txnXP + 100
    }
    
    var xpToNextLevel: Int {
        let nextLevelXP = userLevel * 500
        return nextLevelXP - currentXP
    }
    
    var xpProgress: Double {
        let levelStartXP = (userLevel - 1) * 500
        let levelEndXP = userLevel * 500
        let progress = Double(currentXP - levelStartXP) / Double(levelEndXP - levelStartXP)
        return min(1.0, max(0.0, progress))
    }
    
    func loadDashboard(period: String = "month", anchor: String? = nil) async {
        isLoading = true
        errorMessage = nil
        
        // Load data with TaskGroup to prevent one failure from cancelling others
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadSummary(period: period, anchor: anchor) }
            group.addTask { await self.loadCategories(period: period, anchor: anchor) }
            group.addTask { await self.loadRecentTransactions() }
            group.addTask { await self.loadUserBadges() }
            group.addTask { await self.loadBudgets() }
            group.addTask { await self.loadUsage() }
        }
        
        isLoading = false
    }
    
    private func loadSummary(period: String, anchor: String?) async {
        do {
            summary = try await apiClient.getDashboardSummary(period: period, anchor: anchor)
        } catch {
            errorMessage = ErrorHandler.userFriendlyMessage(for: error)
        }
    }
    
    private func loadCategories(period: String, anchor: String?) async {
        do {
            let response = try await apiClient.getDashboardCategories(period: period, anchor: anchor)
            categories = response.items
        } catch {
            errorMessage = ErrorHandler.userFriendlyMessage(for: error)
        }
    }
    
    private func loadRecentTransactions() async {
        do {
            let response = try await apiClient.getTransactions(limit: 10)
            recentTransactions = response.items
        } catch {
            // Silent fail for transactions - dashboard still works
            print("Failed to load recent transactions: \(error)")
        }
    }
    
    private func loadUserBadges() async {
        do {
            let response = try await apiClient.getUserBadges()
            userBadges = response.items
        } catch {
            // Silent fail for badges
            print("Failed to load user badges: \(error)")
        }
    }
    
    private func loadUsage() async {
        do {
            usage = try await apiClient.getUsage()
        } catch {
            // Silent fail for usage
            print("Failed to load usage: \(error)")
        }
    }
    
    private func loadBudgets() async {
        do {
            let response = try await apiClient.getBudgets()
            budgets = response.items
        } catch {
            // Silent fail for budgets
            print("Failed to load budgets: \(error)")
        }
    }
    
    func loadTrends(months: Int = 6) async {
        do {
            spendingTrends = try await apiClient.getSpendingTrends(months: months)
        } catch {
            errorMessage = ErrorHandler.userFriendlyMessage(for: error)
        }
    }
    
    func loadForecast(monthsAhead: Int = 1) async {
        do {
            forecast = try await apiClient.getSpendingForecast(monthsAhead: monthsAhead)
        } catch {
            errorMessage = ErrorHandler.userFriendlyMessage(for: error)
        }
    }
    
    func loadInsights() async {
        do {
            let response = try await apiClient.getSpendingInsights()
            insights = response.insights
        } catch {
            errorMessage = ErrorHandler.userFriendlyMessage(for: error)
        }
    }
    
    func formatAmount(cents: Int) -> String {
        return CurrencyFormatter.shared.format(cents: cents)
    }
    
    func categoryPercentage(cents: Int, total: Int) -> Double {
        guard total > 0 else { return 0 }
        return (Double(cents) / Double(total)) * 100.0
    }
}

