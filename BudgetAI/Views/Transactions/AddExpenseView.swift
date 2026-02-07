//
//  AddExpenseView.swift
//  BudgetAI
//
//  "Log Spoils" / Gather Resources View
//

import SwiftUI

struct AddExpenseView: View {
    @State private var showingScanner = false
    @State private var showingManual = false
    @State private var isScanning = false
    @State private var animateScanner = false
    @State private var recentTransactions: [Transaction] = []
    @State private var isLoadingReceipts = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.backgroundDark.ignoresSafeArea()
                
                // Background Pattern (Grid)
                Image(systemName: "grid")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 600, height: 600)
                    .foregroundColor(AppColors.primary.opacity(0.05))
                    .rotationEffect(.degrees(30))
                
                VStack(spacing: 32) {
                    
                    // Header
                    VStack(spacing: 8) {
                        Text("Gather Resources")
                            .font(AppTypography.h2)
                            .foregroundColor(.white)
                            .shadow(color: AppColors.primary.opacity(0.5), radius: 10)
                        
                        Text("Scan magical artifacts (receipts)")
                            .font(AppTypography.body)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.top, 40)
                    
                    // Main Scanner Button (Camera Mockup)
                    Button(action: {
                        showingScanner = true
                    }) {
                        ZStack {
                            // Pulse Effect
                            Circle()
                                .fill(AppColors.primary.opacity(0.1))
                                .frame(width: 280, height: 280)
                                .scaleEffect(animateScanner ? 1.1 : 1.0)
                                .opacity(animateScanner ? 0.5 : 1.0)
                                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animateScanner)
                            
                            Circle()
                                .fill(AppColors.backgroundDark)
                                .frame(width: 240, height: 240)
                                .overlay(
                                    Circle()
                                        .stroke(AppColors.primary, lineWidth: 4)
                                )
                            
                            // Crosshair / Scanner UI
                            Image(systemName: "viewfinder")
                                .font(.system(size: 100, weight: .thin))
                                .foregroundColor(AppColors.primary)
                            
                            Image(systemName: "camera.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                            
                            // Scan line animation
                            Rectangle()
                                .fill(AppColors.primary)
                                .frame(width: 200, height: 2)
                                .offset(y: animateScanner ? 80 : -80)
                                .animation(.linear(duration: 2).repeatForever(autoreverses: true), value: animateScanner)
                                .mask(Circle().frame(width: 240, height: 240))
                        }
                    }
                    .padding()
                    
                    // Manual Entry Option
                    Button(action: {
                        showingManual = true
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "pencil.and.scribble")
                                .font(.headline)
                            Text("Scribe Manual Entry")
                                .font(AppTypography.bodyBold)
                        }
                        .foregroundColor(AppColors.accent)
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppColors.accent.opacity(0.3), lineWidth: 1)
                        )
                    }
                    
                    // Recent Scrolls (Recent Receipts)
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("RECENT SCROLLS")
                                .font(AppTypography.small)
                                .foregroundColor(.white.opacity(0.6))
                                .tracking(1)
                            Spacer()
                            NavigationLink(destination: TransactionListView()) {
                                Text("View All")
                                    .font(AppTypography.small)
                                    .foregroundColor(AppColors.primary)
                            }
                        }
                        .padding(.horizontal)
                        
                        if isLoadingReceipts {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .tint(AppColors.primary)
                                Spacer()
                            }
                            .frame(height: 140)
                        } else if recentTransactions.isEmpty {
                            // Empty state - single centered message
                            VStack(spacing: 12) {
                                Image(systemName: "scroll")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white.opacity(0.2))
                                Text("No scrolls yet")
                                    .font(AppTypography.body)
                                    .foregroundColor(.white.opacity(0.4))
                                Text("Scan a receipt to see it here!")
                                    .font(AppTypography.small)
                                    .foregroundColor(.white.opacity(0.3))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 140)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(recentTransactions, id: \.id) { transaction in
                                        RecentScrollCard(transaction: transaction)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    Spacer()
                }
            }
            .onAppear {
                animateScanner = true
                Task {
                    await loadRecentReceipts()
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingScanner) {
                // Link to existing ReceiptCaptureView, wrapped in proper environment
                NavigationView {
                    ReceiptCaptureView()
                }
            }
            .sheet(isPresented: $showingManual) {
                ManualTransactionView()
            }
        }
    }
    
    private func loadRecentReceipts() async {
        isLoadingReceipts = true
        do {
            let response = try await APIClient.shared.getTransactions(limit: 5)
            recentTransactions = response.items
        } catch {
            print("Failed to load recent receipts: \(error)")
        }
        isLoadingReceipts = false
    }
}

struct RecentScrollCard: View {
    let transaction: Transaction
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Source indicator
            HStack {
                Circle()
                    .fill(transaction.source == "receipt" ? AppColors.primary : AppColors.accent)
                    .frame(width: 8, height: 8)
                Spacer()
                Image(systemName: transaction.source == "receipt" ? "doc.viewfinder" : "pencil")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
            
            // Icon
            Image(systemName: iconForCategory)
                .font(.title2)
                .foregroundColor(AppColors.primary)
            
            // Merchant
            Text(transaction.merchant ?? transaction.category.capitalized)
                .font(AppTypography.small)
                .foregroundColor(.white)
                .lineLimit(1)
            
            // Amount
            Text(formatAmount(cents: transaction.total_cents))
                .font(AppTypography.caption)
                .foregroundColor(AppColors.accent)
        }
        .padding(12)
        .frame(width: 100, height: 140)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.primary.opacity(0.2), lineWidth: 1)
        )
    }
    
    var iconForCategory: String {
        switch transaction.category.lowercased() {
        case "food", "groceries", "dining": return "cart.fill"
        case "transport": return "car.fill"
        case "entertainment": return "gamecontroller.fill"
        case "shopping": return "bag.fill"
        case "subscriptions": return "repeat"
        case "utilities": return "bolt.fill"
        default: return "doc.text.fill"
        }
    }
    
    func formatAmount(cents: Int) -> String {
        let dollars = Double(cents) / 100.0
        return String(format: "$%.2f", dollars)
    }
}

#Preview {
    AddExpenseView()
}
