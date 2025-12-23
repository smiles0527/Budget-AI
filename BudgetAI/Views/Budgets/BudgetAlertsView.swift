//
//  BudgetAlertsView.swift
//  testapp
//
//  Budget alerts display
//

import SwiftUI

struct BudgetAlertsView: View {
    @StateObject private var viewModel = BudgetAlertsViewModel()
    
    var body: some View {
        List {
            if viewModel.isLoading && viewModel.alerts.isEmpty {
                ProgressView()
            } else if viewModel.alerts.isEmpty {
                Text("No alerts")
                    .foregroundColor(.secondary)
            } else {
                ForEach(viewModel.alerts, id: \.id) { alert in
                    AlertRow(alert: alert, viewModel: viewModel)
                }
            }
        }
        .navigationTitle("Budget Alerts")
        .refreshable {
            await viewModel.loadAlerts()
        }
        .task {
            await viewModel.loadAlerts()
        }
    }
}

struct AlertRow: View {
    let alert: BudgetAlert
    @ObservedObject var viewModel: BudgetAlertsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: iconForType(alert.alert_type))
                    .foregroundColor(colorForType(alert.alert_type))
                
                Text(alert.message)
                    .font(.headline)
                
                Spacer()
            }
            
            if let category = alert.category {
                Text("Category: \(category.capitalized)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let current = alert.current_cents, let threshold = alert.threshold_cents {
                Text("Spent: \(CurrencyFormatter.shared.format(cents: current)) / \(CurrencyFormatter.shared.format(cents: threshold))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(alert.created_at.toDisplayDate())
                .font(.caption)
                .foregroundColor(.secondary)
            
            if alert.status == "active" {
                HStack {
                    Button("Dismiss") {
                        Task {
                            await viewModel.dismissAlert(alertId: alert.id)
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                    
                    Spacer()
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func iconForType(_ type: String) -> String {
        switch type {
        case "budget_exceeded": return "exclamationmark.triangle.fill"
        case "budget_warning": return "exclamationmark.circle.fill"
        default: return "info.circle.fill"
        }
    }
    
    private func colorForType(_ type: String) -> Color {
        switch type {
        case "budget_exceeded": return .red
        case "budget_warning": return .orange
        default: return .blue
        }
    }
}

@MainActor
class BudgetAlertsViewModel: ObservableObject {
    @Published var alerts: [BudgetAlert] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiClient = APIClient.shared
    
    func loadAlerts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiClient.getAlerts(status: "active")
            alerts = response.items
        } catch {
            errorMessage = ErrorHandler.userFriendlyMessage(for: error)
        }
        
        isLoading = false
    }
    
    func dismissAlert(alertId: String) async {
        do {
            try await apiClient.updateAlert(alertId: alertId, status: "dismissed")
            await loadAlerts()
        } catch {
            errorMessage = ErrorHandler.userFriendlyMessage(for: error)
        }
    }
}

#Preview {
    NavigationView {
        BudgetAlertsView()
    }
}

