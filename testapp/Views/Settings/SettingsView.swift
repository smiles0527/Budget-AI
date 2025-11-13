//
//  SettingsView.swift
//  testapp
//
//  Settings screen
//

import SwiftUI
import UIKit

struct SettingsView: View {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var profileViewModel = ProfileViewModel()
    @State private var showingEditProfile = false
    
    var body: some View {
        NavigationView {
            List {
                Section("Account") {
                    HStack {
                        Text("Email")
                        Spacer()
                        Text(authManager.currentUser?.email ?? "-")
                            .foregroundColor(.secondary)
                    }
                    
                    if let subscription = authManager.subscription {
                        HStack {
                            Text("Plan")
                            Spacer()
                            Text(subscription.plan.capitalized)
                                .foregroundColor(.secondary)
                        }
                        
                        if subscription.plan == "free" {
                            NavigationLink("Upgrade to Premium") {
                                SubscriptionView()
                            }
                        }
                    }
                }
                
                Section("Preferences") {
                    NavigationLink("Edit Profile") {
                        EditProfileView(viewModel: profileViewModel)
                    }
                    
                    NavigationLink("Notifications") {
                        NotificationsSettingsView()
                    }
                }
                
                Section("Data") {
                    NavigationLink("Export Data") {
                        ExportDataView()
                    }
                    
                    NavigationLink("Privacy") {
                        PrivacyView()
                    }
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Link("Help & Support", destination: URL(string: "https://snapbudget.app/support")!)
                    Link("Terms of Service", destination: URL(string: "https://snapbudget.app/terms")!)
                    Link("Privacy Policy", destination: URL(string: "https://snapbudget.app/privacy")!)
                }
                
                Section("Danger Zone") {
                    NavigationLink("Delete Account") {
                        DeleteAccountView()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Settings")
        }
    }
}

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: ProfileViewModel
    @State private var displayName = ""
    @State private var currencyCode = "USD"
    @State private var timezone = "UTC"
    
    let currencies = ["USD", "EUR", "GBP", "CAD", "AUD", "JPY"]
    
    var body: some View {
        Form {
            Section("Profile") {
                TextField("Display Name", text: $displayName)
                
                Picker("Currency", selection: $currencyCode) {
                    ForEach(currencies, id: \.self) { currency in
                        Text(currency).tag(currency)
                    }
                }
                
                TextField("Timezone", text: $timezone)
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    Task {
                        await viewModel.updateProfile(
                            displayName: displayName.isEmpty ? nil : displayName,
                            currencyCode: currencyCode,
                            timezone: timezone
                        )
                        dismiss()
                    }
                }
            }
        }
        .task {
            await viewModel.loadProfile()
            if let profile = viewModel.profile {
                displayName = profile.display_name ?? ""
                currencyCode = profile.currency_code
                timezone = profile.timezone
            }
        }
    }
}

struct ProfileViewModel: ObservableObject {
    @Published var profile: Profile?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiClient = APIClient.shared
    
    func loadProfile() async {
        do {
            let response = try await apiClient.getCurrentUser()
            profile = response.profile
        } catch {
            errorMessage = ErrorHandler.userFriendlyMessage(for: error)
        }
    }
    
    func updateProfile(displayName: String?, currencyCode: String, timezone: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await apiClient.updateProfile(
                displayName: displayName,
                currencyCode: currencyCode,
                timezone: timezone
            )
            await loadProfile()
        } catch {
            errorMessage = ErrorHandler.userFriendlyMessage(for: error)
        }
        
        isLoading = false
    }
}

struct NotificationsSettingsView: View {
    @State private var budgetAlerts = true
    @State private var goalAchievements = true
    @State private var weeklySummary = false
    
    var body: some View {
        Form {
            Section("Alerts") {
                Toggle("Budget Warnings", isOn: $budgetAlerts)
                Toggle("Goal Achievements", isOn: $goalAchievements)
            }
            
            Section("Reports") {
                Toggle("Weekly Summary", isOn: $weeklySummary)
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ExportDataView: View {
    @State private var isExporting = false
    @State private var exportMessage: String?
    @State private var jobId: String?
    @State private var showingStatusView = false
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Export your transaction data as a CSV file")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
            
            Button(action: exportData) {
                if isExporting {
                    ProgressView()
                } else {
                    Text("Export CSV")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isExporting)
            
            if let message = exportMessage {
                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
            }
            
            if let jobId = jobId {
                NavigationLink("Check Export Status", destination: ExportStatusView(jobId: jobId))
                    .buttonStyle(.bordered)
            }
        }
        .navigationTitle("Export Data")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func exportData() {
        isExporting = true
        exportMessage = nil
        jobId = nil
        
        Task {
            do {
                let apiClient = APIClient.shared
                let calendar = Calendar.current
                let endDate = Date()
                let startDate = calendar.date(byAdding: .month, value: -12, to: endDate) ?? endDate
                
                let response = try await apiClient.exportCSV(
                    fromDate: startDate.toInputString(),
                    toDate: endDate.toInputString(),
                    wait: false
                )
                
                if let downloadURL = response.download_url {
                    exportMessage = "Export ready! Download URL: \(downloadURL)"
                    if let url = URL(string: downloadURL) {
                        UIApplication.shared.open(url)
                    }
                } else if let jobId = response.job_id {
                    self.jobId = jobId
                    exportMessage = "Export started. Job ID: \(jobId)"
                } else {
                    exportMessage = "Export started. Please check back later."
                }
            } catch {
                exportMessage = ErrorHandler.userFriendlyMessage(for: error)
            }
            
            isExporting = false
        }
    }
}

struct ExportStatusView: View {
    let jobId: String
    @State private var status: ExportCSVResponse?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 24) {
            if isLoading {
                ProgressView()
            } else if let status = status {
                if let downloadURL = status.download_url {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.green)
                        
                        Text("Export Ready!")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Link("Download CSV", destination: URL(string: downloadURL)!)
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("Export in progress...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            } else if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .padding()
        .navigationTitle("Export Status")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await checkStatus()
        }
        .refreshable {
            await checkStatus()
        }
    }
    
    private func checkStatus() async {
        isLoading = true
        errorMessage = nil
        
        do {
            status = try await APIClient.shared.getExportStatus(jobId: jobId)
        } catch {
            errorMessage = ErrorHandler.userFriendlyMessage(for: error)
        }
        
        isLoading = false
    }
}

struct SubscriptionView: View {
    @State private var isLoading = false
    @State private var checkoutURL: String?
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Text("Premium Features")
                    .font(.title2)
                    .fontWeight(.bold)
                
                VStack(alignment: .leading, spacing: 12) {
                    FeatureRow(icon: "infinity", text: "Unlimited receipt scans")
                    FeatureRow(icon: "square.and.arrow.down", text: "CSV export")
                    FeatureRow(icon: "pencil", text: "Manual transaction entry")
                    FeatureRow(icon: "xmark.circle", text: "Ad-free experience")
                }
                .padding()
            }
            
            Button(action: startCheckout) {
                if isLoading {
                    ProgressView()
                } else {
                    Text("Subscribe - $4.99/month")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isLoading)
            
            if let urlString = checkoutURL, let url = URL(string: urlString) {
                Link("Complete Subscription", destination: url)
                    .buttonStyle(.bordered)
            }
        }
        .padding()
        .navigationTitle("Upgrade")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func startCheckout() {
        isLoading = true
        
        Task {
            do {
                let apiClient = APIClient.shared
                let response = try await apiClient.getSubscriptionCheckout()
                checkoutURL = response.checkout_url
            } catch {
                // Handle error
            }
            isLoading = false
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
            Text(text)
        }
    }
}

struct PrivacyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Privacy Policy")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("""
                Your financial data is encrypted and stored securely. We use industry-standard encryption (AES-256) for data at rest and TLS for data in transit.
                
                We never share your individual transaction data with third parties. Aggregated, anonymized insights may be used for market research.
                
                You can delete your account and all associated data at any time from the Profile settings.
                """)
                .font(.body)
            }
            .padding()
        }
        .navigationTitle("Privacy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SettingsView()
}

