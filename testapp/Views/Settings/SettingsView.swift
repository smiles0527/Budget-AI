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
                    
                    NavigationLink("Privacy Controls") {
                        PrivacyControlsView()
                    }
                    
                    NavigationLink("Privacy Policy") {
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
            // Check premium status
            let authManager = AuthManager.shared
            let isPremium = authManager.subscription?.plan == "premium" && 
                           authManager.subscription?.status == "active"
            
            guard isPremium else {
                exportMessage = "CSV export is a Premium feature. Please upgrade to export your data."
                isExporting = false
                return
            }
            
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
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var viewModel = SubscriptionViewModel()
    @State private var showingCancelAlert = false
    @State private var showingCheckout = false
    
    var isPremium: Bool {
        authManager.subscription?.plan == "premium" && authManager.subscription?.status == "active"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Current Plan Status
                if isPremium {
                    VStack(spacing: 16) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.yellow)
                        
                        Text("Premium Active")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        if let subscription = authManager.subscription {
                            VStack(spacing: 8) {
                                if let periodEnd = subscription.current_period_end {
                                    Text("Renews: \(periodEnd.toDisplayDate())")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                if subscription.status == "canceled" || subscription.cancel_at_period_end == true {
                                    Text("Cancels at period end")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.yellow.opacity(0.1))
                    .cornerRadius(12)
                } else {
                    VStack(spacing: 16) {
                        Text("Free Plan")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Upgrade to unlock premium features")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
                
                // Premium Features
                VStack(alignment: .leading, spacing: 16) {
                    Text("Premium Features")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        FeatureRow(icon: "infinity", text: "Unlimited receipt scans")
                        FeatureRow(icon: "square.and.arrow.down", text: "CSV export")
                        FeatureRow(icon: "pencil", text: "Manual transaction entry")
                        FeatureRow(icon: "chart.bar.fill", text: "Advanced analytics")
                        FeatureRow(icon: "xmark.circle", text: "Ad-free experience")
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                
                // Pricing
                if !isPremium {
                    VStack(spacing: 12) {
                        Text("$4.99/month")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Cancel anytime")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
                
                // Action Buttons
                if isPremium {
                    if authManager.subscription?.cancel_at_period_end != true {
                        Button(action: { showingCancelAlert = true }) {
                            Text("Cancel Subscription")
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(12)
                        }
                    } else {
                        Button(action: {
                            Task {
                                await viewModel.resumeSubscription()
                                await authManager.refreshUser()
                            }
                        }) {
                            Text("Resume Subscription")
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(12)
                        }
                    }
                } else {
                    Button(action: {
                        showingCheckout = true
                        Task {
                            await viewModel.startCheckout()
                        }
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Upgrade to Premium")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(viewModel.isLoading)
                }
                
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
        }
        .navigationTitle("Subscription")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Cancel Subscription", isPresented: $showingCancelAlert) {
            Button("Keep Subscription", role: .cancel) {}
            Button("Cancel", role: .destructive) {
                Task {
                    await viewModel.cancelSubscription()
                    await authManager.refreshUser()
                }
            }
        } message: {
            Text("Your subscription will remain active until the end of the current billing period. You can resume anytime before then.")
        }
        .sheet(isPresented: $showingCheckout) {
            if let checkoutURL = viewModel.checkoutURL, let url = URL(string: checkoutURL) {
                SafariWebView(url: url)
            }
        }
        .task {
            await authManager.refreshUser()
        }
    }
}

@MainActor
class SubscriptionViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var checkoutURL: String?
    @Published var errorMessage: String?
    
    private let apiClient = APIClient.shared
    
    func startCheckout() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiClient.getSubscriptionCheckout()
            checkoutURL = response.checkout_url
        } catch {
            errorMessage = ErrorHandler.userFriendlyMessage(for: error)
        }
        
        isLoading = false
    }
    
    func cancelSubscription() async {
        isLoading = true
        errorMessage = nil
        
        // Note: This would require a backend endpoint
        // For now, we'll show a message that cancellation should be done via Stripe customer portal
        errorMessage = "To cancel your subscription, please contact support or use the Stripe customer portal."
        
        isLoading = false
    }
    
    func resumeSubscription() async {
        isLoading = true
        errorMessage = nil
        
        // Note: This would require a backend endpoint
        errorMessage = "To resume your subscription, please contact support."
        
        isLoading = false
    }
}

struct SafariWebView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> UIViewController {
        let vc = UIViewController()
        DispatchQueue.main.async {
            UIApplication.shared.open(url)
        }
        return vc
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
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

