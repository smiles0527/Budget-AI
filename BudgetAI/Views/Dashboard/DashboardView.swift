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
                                Text("Budgeteer Level \(viewModel.userLevel)")
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
                                                .frame(width: g.size.width * viewModel.xpProgress)
                                                .cornerRadius(4)
                                        }
                                    }
                                    .frame(height: 6)
                                    .frame(width: 150)
                                    
                                    Text("\(viewModel.xpToNextLevel) XP to Level \(viewModel.userLevel + 1)")
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
                                    
                                    if !viewModel.userBadges.isEmpty {
                                        Circle()
                                            .fill(AppColors.error)
                                            .frame(width: 10, height: 10)
                                            .offset(x: 10, y: -10)
                                    }
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
                                            
                                            if viewModel.totalBudgetLimit > 0 {
                                                Text("/ \(viewModel.formatAmount(cents: viewModel.totalBudgetLimit))")
                                                    .font(AppTypography.bodyBold)
                                                    .foregroundColor(AppColors.textPrimary.opacity(0.6))
                                            } else {
                                                Text("spent this month")
                                                    .font(AppTypography.bodyBold)
                                                    .foregroundColor(AppColors.textPrimary.opacity(0.6))
                                            }
                                        }
                                    }
                                    Spacer()
                                    Image(systemName: "shield.check.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(AppColors.primaryDark.opacity(0.3))
                                }
                                
                                // HP Bar (Budget Health)
                                if viewModel.totalBudgetLimit > 0 {
                                    GeometryReader { g in
                                        ZStack(alignment: .leading) {
                                            Rectangle()
                                                .fill(Color.black.opacity(0.1))
                                                .cornerRadius(8)
                                            
                                            Rectangle()
                                                .fill(LinearGradient(
                                                    colors: viewModel.budgetHealthProgress > 0.3 
                                                        ? [AppColors.success, AppColors.primaryDark] 
                                                        : [AppColors.error, AppColors.accent],
                                                    startPoint: .leading, 
                                                    endPoint: .trailing
                                                ))
                                                .frame(width: g.size.width * viewModel.budgetHealthProgress)
                                                .cornerRadius(8)
                                                .overlay(
                                                    Rectangle()
                                                        .fill(Color.white.opacity(0.3))
                                                        .frame(width: g.size.width * viewModel.budgetHealthProgress, height: 2)
                                                        .offset(y: -5)
                                                )
                                        }
                                    }
                                    .frame(height: 16)
                                } else {
                                    // No budget set - show prompt
                                    Text("Set a budget to track your progress!")
                                        .font(AppTypography.small)
                                        .foregroundColor(AppColors.textPrimary.opacity(0.7))
                                }
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(AppColors.primary)
                            )
                            .shadow(color: AppColors.primary.opacity(0.3), radius: 15, y: 5)
                            .padding(.horizontal)
                        } else if viewModel.isLoading {
                             // Loading State
                             RoundedRectangle(cornerRadius: 24)
                                .fill(Color.white.opacity(0.05))
                                .frame(height: 140)
                                .overlay(ProgressView().tint(.white))
                                .padding(.horizontal)
                        } else {
                            // Empty State - No Data Yet
                            VStack(spacing: 12) {
                                Image(systemName: "chart.bar.doc.horizontal")
                                    .font(.system(size: 40))
                                    .foregroundColor(AppColors.primary.opacity(0.5))
                                Text("No spending data yet")
                                    .font(AppTypography.body)
                                    .foregroundColor(.white.opacity(0.7))
                                Text("Add your first transaction to see your stats!")
                                    .font(AppTypography.small)
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(30)
                            .background(
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(Color.white.opacity(0.05))
                            )
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
                                if viewModel.recentTransactions.isEmpty {
                                    // Empty state
                                    VStack(spacing: 12) {
                                        Image(systemName: "tray")
                                            .font(.system(size: 40))
                                            .foregroundColor(.white.opacity(0.3))
                                        Text("No transactions yet")
                                            .font(AppTypography.body)
                                            .foregroundColor(.white.opacity(0.5))
                                        Text("Scan a receipt or add a transaction to get started!")
                                            .font(AppTypography.small)
                                            .foregroundColor(.white.opacity(0.3))
                                            .multilineTextAlignment(.center)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 40)
                                } else {
                                    ForEach(viewModel.recentTransactions.prefix(5), id: \.id) { transaction in
                                        BattleRow(
                                            title: transaction.merchant ?? transaction.category.capitalized,
                                            amount: viewModel.formatAmount(cents: -transaction.total_cents),
                                            date: formatTransactionDate(transaction.txn_date),
                                            isCrit: transaction.total_cents > 10000 // "Critical hit" for > $100
                                        )
                                    }
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
            .task(id: selectedPeriod) {
                await viewModel.loadDashboard(period: selectedPeriod)
            }
            .refreshable {
                await viewModel.loadDashboard(period: selectedPeriod)
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
    
    func formatTransactionDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        
        guard let date = formatter.date(from: dateString) else {
            // Try alternative format
            let altFormatter = DateFormatter()
            altFormatter.dateFormat = "yyyy-MM-dd"
            guard let altDate = altFormatter.date(from: dateString) else {
                return dateString
            }
            return formatRelativeDate(altDate)
        }
        return formatRelativeDate(date)
    }
    
    private func formatRelativeDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
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


