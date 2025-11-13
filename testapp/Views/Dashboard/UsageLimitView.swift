//
//  UsageLimitView.swift
//  testapp
//
//  Usage limit display for freemium users
//

import SwiftUI

struct UsageLimitView: View {
    @StateObject private var viewModel = UsageViewModel()
    @StateObject private var authManager = AuthManager.shared
    @State private var showingUpgrade = false
    
    var isPremium: Bool {
        authManager.subscription?.plan == "premium" && 
        authManager.subscription?.status == "active"
    }
    
    var body: some View {
        if !isPremium, let usage = viewModel.usage, let remaining = usage.scans_remaining, remaining != -1 {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "camera.fill")
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Scans This Month")
                            .font(.headline)
                        
                        if remaining == 0 {
                            Text("Limit reached")
                                .font(.subheadline)
                                .foregroundColor(.red)
                        } else {
                            Text("\(remaining) remaining")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: { showingUpgrade = true }) {
                        Text("Upgrade")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .cornerRadius(20)
                    }
                }
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)
                            .cornerRadius(4)
                        
                        Rectangle()
                            .fill(progressColor)
                            .frame(
                                width: geometry.size.width * progressPercentage,
                                height: 8
                            )
                            .cornerRadius(4)
                    }
                }
                .frame(height: 8)
            }
            .padding()
            .background(Color.blue.opacity(0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(remaining == 0 ? Color.red.opacity(0.3) : Color.clear, lineWidth: 2)
            )
            .sheet(isPresented: $showingUpgrade) {
                UpgradeView()
            }
            .task {
                await viewModel.loadUsage()
            }
        }
    }
    
    private var progressPercentage: Double {
        guard let usage = viewModel.usage,
              let remaining = usage.scans_remaining,
              remaining != -1 else { return 0 }
        
        let total = usage.scans_used + remaining
        guard total > 0 else { return 0 }
        
        return Double(usage.scans_used) / Double(total)
    }
    
    private var progressColor: Color {
        let progress = progressPercentage
        if progress >= 1.0 {
            return .red
        } else if progress >= 0.8 {
            return .orange
        } else {
            return .blue
        }
    }
}

struct UpgradeView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var authManager = AuthManager.shared
    @State private var isLoading = false
    @State private var checkoutURL: String?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.yellow)
                        
                        Text("Upgrade to Premium")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Unlock unlimited scans and premium features")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    
                    // Features
                    VStack(alignment: .leading, spacing: 16) {
                        FeatureRow(icon: "infinity", title: "Unlimited Scans", description: "No monthly limits")
                        FeatureRow(icon: "chart.bar.fill", title: "Advanced Analytics", description: "Detailed insights and reports")
                        FeatureRow(icon: "square.and.arrow.down", title: "CSV Export", description: "Export your data anytime")
                        FeatureRow(icon: "pencil", title: "Manual Transactions", description: "Add transactions manually")
                        FeatureRow(icon: "bell.badge.fill", title: "Priority Support", description: "Get help faster")
                    }
                    .padding()
                    
                    // Pricing
                    VStack(spacing: 12) {
                        Text("$4.99/month")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("or $49/year (save 18%)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Upgrade Button
                    Button(action: {
                        Task {
                            await startCheckout()
                        }
                    }) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Upgrade Now")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isLoading)
                    
                    Text("Cancel anytime. No hidden fees.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            .navigationTitle("Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .sheet(item: Binding(
                get: { checkoutURL != nil ? checkoutURL : nil },
                set: { checkoutURL = $0 }
            )) { url in
                SafariView(url: URL(string: url)!)
            }
        }
    }
    
    private func startCheckout() async {
        isLoading = true
        do {
            let response = try await APIClient.shared.getSubscriptionCheckout()
            checkoutURL = response.checkout_url
        } catch {
            print("Error starting checkout: \(error)")
        }
        isLoading = false
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// Helper for displaying URLs
extension String: Identifiable {
    public var id: String { self }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> UIViewController {
        let vc = UIViewController()
        // In a real app, you'd use SFSafariViewController here
        // For now, just open in Safari
        DispatchQueue.main.async {
            UIApplication.shared.open(url)
        }
        return vc
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

#Preview {
    UsageLimitView()
        .padding()
}

