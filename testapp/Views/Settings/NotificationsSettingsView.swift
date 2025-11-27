//
//  NotificationsSettingsView.swift
//  testapp
//
//  Notification settings screen
//

import SwiftUI

struct NotificationsSettingsView: View {
    @StateObject private var viewModel = NotificationSettingsViewModel()
    
    var body: some View {
        Form {
            if viewModel.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            }
            
            Section("Alerts") {
                Toggle("Budget Warnings", isOn: $viewModel.budgetAlerts)
                    .onChange(of: viewModel.budgetAlerts) { _ in
                        Task { await viewModel.updateSettings() }
                    }
                
                Toggle("Goal Achievements", isOn: $viewModel.goalAchievements)
                    .onChange(of: viewModel.goalAchievements) { _ in
                        Task { await viewModel.updateSettings() }
                    }
                
                Toggle("Streak Reminders", isOn: $viewModel.streakReminders)
                    .onChange(of: viewModel.streakReminders) { _ in
                        Task { await viewModel.updateSettings() }
                    }
            }
            
            Section("Reports") {
                Toggle("Weekly Summary", isOn: $viewModel.weeklySummary)
                    .onChange(of: viewModel.weeklySummary) { _ in
                        Task { await viewModel.updateSettings() }
                    }
            }
            
            if let error = viewModel.errorMessage {
                Section {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadSettings()
        }
    }
}

@MainActor
class NotificationSettingsViewModel: ObservableObject {
    @Published var budgetAlerts = true
    @Published var goalAchievements = true
    @Published var streakReminders = true
    @Published var weeklySummary = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiClient = APIClient.shared
    
    func loadSettings() async {
        isLoading = true
        errorMessage = nil
        do {
            let response = try await apiClient.getCurrentUser()
            if let profile = response.profile {
                self.budgetAlerts = profile.notification_budget_alerts ?? true
                self.goalAchievements = profile.notification_goal_achieved ?? true
                self.streakReminders = profile.notification_streak_reminders ?? true
                self.weeklySummary = profile.notification_weekly_summary ?? false
            }
        } catch {
            errorMessage = ErrorHandler.userFriendlyMessage(for: error)
        }
        isLoading = false
    }
    
    func updateSettings() async {
        // Debounce could be added here to avoid too many requests
        do {
            try await apiClient.updateProfile(
                notificationBudgetAlerts: budgetAlerts,
                notificationGoalAchieved: goalAchievements,
                notificationStreakReminders: streakReminders,
                notificationWeeklySummary: weeklySummary
            )
        } catch {
            errorMessage = ErrorHandler.userFriendlyMessage(for: error)
        }
    }
}

#Preview {
    NavigationView {
        NotificationsSettingsView()
    }
}
