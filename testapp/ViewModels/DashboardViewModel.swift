//
//  DashboardViewModel.swift
//  testapp
//
//  ViewModel for dashboard data
//

import Foundation
import Combine

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var summary: DashboardSummary?
    @Published var categories: [CategorySpending] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    @Published var spendingTrends: SpendingTrendsResponse?
    @Published var forecast: SpendingForecastResponse?
    @Published var insights: [Insight] = []
    
    private let apiClient = APIClient.shared
    
    func loadDashboard(period: String = "month", anchor: String? = nil) async {
        isLoading = true
        errorMessage = nil
        
        async let summaryTask = loadSummary(period: period, anchor: anchor)
        async let categoriesTask = loadCategories(period: period, anchor: anchor)
        
        await summaryTask
        await categoriesTask
        
        isLoading = false
    }
    
    private func loadSummary(period: String, anchor: String?) async {
        do {
            summary = try await apiClient.getDashboardSummary(period: period, anchor: anchor)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func loadCategories(period: String, anchor: String?) async {
        do {
            let response = try await apiClient.getDashboardCategories(period: period, anchor: anchor)
            categories = response.items
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func loadTrends(months: Int = 6) async {
        do {
            spendingTrends = try await apiClient.getSpendingTrends(months: months)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func loadForecast(monthsAhead: Int = 1) async {
        do {
            forecast = try await apiClient.getSpendingForecast(monthsAhead: monthsAhead)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func loadInsights() async {
        do {
            let response = try await apiClient.getSpendingInsights()
            insights = response.insights
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func formatAmount(cents: Int) -> String {
        let dollars = Double(cents) / 100.0
        return String(format: "$%.2f", dollars)
    }
    
    func categoryPercentage(cents: Int, total: Int) -> Double {
        guard total > 0 else { return 0 }
        return (Double(cents) / Double(total)) * 100.0
    }
}

