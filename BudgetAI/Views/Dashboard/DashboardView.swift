//
//  DashboardView.swift
//  BudgetAI
//
//  "Battle Arena" Dashboard
//

import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @State private var selectedPeriod = "month"
    @State private var animatePulse = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.backgroundDark.ignoresSafeArea()
                
                // Background Effects
                VStack {
                    Circle()
                        .fill(AppColors.primary.opacity(0.1))
                        .frame(width: 400, height: 400)
                        .blur(radius: 100)
                        .offset(x: -150, y: -200)
                    Spacer()
                }
                
                ScrollView {
                    VStack(spacing: 24) {
                        
                        // MARK: - Header (Player Stats)
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .stroke(LinearGradient(colors: [AppColors.primary, AppColors.primaryDark], startPoint: .top, endPoint: .bottom), lineWidth: 3)
                                    .frame(width: 64, height: 64)
                                
                                Image(systemName: "person.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(AppColors.primary)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Budgeteer Level 5")
                                    .font(AppTypography.h4)
                                    .foregroundColor(.white)
                                
                                // XP Bar
                                VStack(alignment: .leading, spacing: 2) {
                                    GeometryReader { g in
                                        ZStack(alignment: .leading) {
                                            Rectangle()
                                                .fill(Color.white.opacity(0.1))
                                                .cornerRadius(4)
                                            
                                            Rectangle()
                                                .fill(AppColors.primary)
                                                .frame(width: g.size.width * 0.7) // Mock 70% XP
                                                .cornerRadius(4)
                                        }
                                    }
                                    .frame(height: 6)
                                    .frame(width: 150)
                                    
                                    Text("450 XP to Level 6")
                                        .font(AppTypography.small)
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }
                            
                            Spacer()
                            
                            // Notifications / Quests
                            Button(action: {}) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.1))
                                        .frame(width: 40, height: 40)
                                    
                                    Image(systemName: "bell.fill")
                                        .foregroundColor(.white)
                                    
                                    Circle()
                                        .fill(AppColors.error)
                                        .frame(width: 10, height: 10)
                                        .offset(x: 10, y: -10)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                        
                        // MARK: - War Chest (Budget Overview)
                        if let summary = viewModel.summary {
                            VStack(spacing: 16) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("WAR CHEST CAPACITY")
                                            .font(AppTypography.small)
                                            .foregroundColor(AppColors.primaryDark)
                                            .tracking(1)
                                        
                                        HStack(alignment: .firstTextBaseline) {
                                            Text(viewModel.formatAmount(cents: summary.total_spend_cents))
                                                .font(.system(size: 32, weight: .black, design: .rounded))
                                                .foregroundColor(AppColors.textPrimary)
                                            
                                            Text("/ \(viewModel.formatAmount(cents: 200000))") // Placeholder limit
                                                .font(AppTypography.bodyBold)
                                                .foregroundColor(AppColors.textPrimary.opacity(0.6))
                                        }
                                    }
                                    Spacer()
                                    Image(systemName: "shield.check.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(AppColors.primaryDark.opacity(0.3))
                                }
                                
                                // HP Bar (Budget Health)
                                GeometryReader { g in
                                    ZStack(alignment: .leading) {
                                        Rectangle()
                                            .fill(Color.black.opacity(0.1))
                                            .cornerRadius(8)
                                        
                                        Rectangle()
                                            .fill(LinearGradient(colors: [AppColors.success, AppColors.primaryDark], startPoint: .leading, endPoint: .trailing))
                                            .frame(width: g.size.width * 0.65)
                                            .cornerRadius(8)
                                            .overlay(
                                                Rectangle()
                                                    .fill(Color.white.opacity(0.3))
                                                    .frame(width: g.size.width * 0.65, height: 2)
                                                    .offset(y: -5)
                                            )
                                    }
                                }
                                .frame(height: 16)
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(AppColors.primary)
                            )
                            .shadow(color: AppColors.primary.opacity(0.3), radius: 15, y: 5)
                            .padding(.horizontal)
                        } else {
                             // Loading State
                             RoundedRectangle(cornerRadius: 24)
                                .fill(Color.white.opacity(0.05))
                                .frame(height: 140)
                                .padding(.horizontal)
                        }
                        
                        // MARK: - Resources (CategoriesGrid)
                        VStack(alignment: .leading, spacing: 16) {
                            Text("RESOURCES")
                                .font(AppTypography.h4)
                                .foregroundColor(.white)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    if viewModel.categories.isEmpty {
                                        ForEach(0..<3) { _ in
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(Color.white.opacity(0.05))
                                                .frame(width: 140, height: 140)
                                        }
                                    } else {
                                        ForEach(viewModel.categories.prefix(5), id: \.category) { category in
                                            ResourceCard(
                                                title: category.category.capitalized,
                                                amount: viewModel.formatAmount(cents: category.total_spend_cents),
                                                icon: iconForCategory(category.category),
                                                color: colorForCategory(category.category)
                                            )
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // MARK: - Recent Battles (Transactions)
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("RECENT BATTLES")
                                    .font(AppTypography.h4)
                                    .foregroundColor(.white)
                                Spacer()
                                Button("View All") {
                                    // Action
                                }
                                .font(AppTypography.small)
                                .foregroundColor(AppColors.primary)
                            }
                            .padding(.horizontal)
                            
                            VStack(spacing: 12) {
                                ForEach(0..<5) { i in
                                    BattleRow(
                                        title: ["Grocery Run", "Fuel Up", "Netflix Sub", "Coffee Break", "Gym Membership"][i],
                                        amount: ["-$124.50", "-$45.00", "-$15.99", "-$4.50", "-$29.99"][i],
                                        date: "Today",
                                        isCrit: i == 0
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Padding for TabBar
                        Spacer().frame(height: 100)
                    }
                }
            }
            .navigationBarHidden(true)
            .task {
                await viewModel.loadDashboard(period: selectedPeriod)
                await viewModel.loadTrends(months: 6)
            }
        }
    }
    
    // Helper Maps (To be moved to ViewModel logic later)
    func iconForCategory(_ category: String) -> String {
        switch category.lowercased() {
        case "food", "groceries": return "cart.fill"
        case "transport": return "fuelpump.fill"
        case "entertainment": return "gamecontroller.fill"
        default: return "bag.fill"
        }
    }
    
    func colorForCategory(_ category: String) -> Color {
        switch category.lowercased() {
        case "food": return AppColors.accent
        case "transport": return AppColors.rare
        case "entertainment": return AppColors.epic
        default: return AppColors.primary
        }
    }
}

// MARK: - Subcomponents

struct ResourceCard: View {
    let title: String
    let amount: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: icon)
                        .foregroundColor(color)
                )
            
            Spacer()
            
            Text(title)
                .font(AppTypography.caption)
                .foregroundColor(.white.opacity(0.7))
            
            Text(amount)
                .font(AppTypography.h4)
                .foregroundColor(.white)
        }
        .padding()
        .frame(width: 140, height: 140)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

struct BattleRow: View {
    let title: String
    let amount: String
    let date: String
    let isCrit: Bool
    
    var body: some View {
        HStack {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 48, height: 48)
                
                Image(systemName: "sword.fill")
                    .foregroundColor(isCrit ? AppColors.error : .white.opacity(0.5))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppTypography.bodyBold)
                    .foregroundColor(.white)
                
                Text(date)
                    .font(AppTypography.small)
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
            
            Text(amount)
                .font(AppTypography.h4)
                .foregroundColor(AppColors.error)
                .shadow(color: isCrit ? AppColors.error.opacity(0.5) : .clear, radius: 8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.3))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isCrit ? AppColors.error.opacity(0.5) : Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}

#Preview {
    DashboardView()
}


