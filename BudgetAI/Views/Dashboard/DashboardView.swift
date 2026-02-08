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
                        .fill(AppColors.primary.opacity(0.08))
                        .frame(width: 350, height: 350)
                        .blur(radius: 100)
                        .offset(x: -150, y: -200)
                    Spacer()
                }
                VStack {
                    Spacer()
                    Circle()
                        .fill(AppColors.epic.opacity(0.06))
                        .frame(width: 300, height: 300)
                        .blur(radius: 100)
                        .offset(x: 160, y: 50)
                }
                VStack {
                    Circle()
                        .fill(AppColors.rare.opacity(0.05))
                        .frame(width: 250, height: 250)
                        .blur(radius: 80)
                        .offset(x: 100, y: -50)
                    Spacer()
                }
                
                ScrollView {
                    VStack(spacing: 18) {
                        
                        // MARK: - Header (Player Stats)
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .stroke(LinearGradient(colors: [AppColors.accent, AppColors.epic, AppColors.rare], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 2.5)
                                    .frame(width: 44, height: 44)
                                
                                Image(systemName: "person.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(AppColors.accent)
                            }
                            
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Budgeteer Level \(viewModel.userLevel)")
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                                
                                // XP Bar
                                VStack(alignment: .leading, spacing: 2) {
                                    GeometryReader { g in
                                        ZStack(alignment: .leading) {
                                            Rectangle()
                                                .fill(Color.white.opacity(0.1))
                                                .cornerRadius(3)
                                            
                                            Rectangle()
                                                .fill(LinearGradient(colors: [AppColors.rare, AppColors.epic], startPoint: .leading, endPoint: .trailing))
                                                .frame(width: g.size.width * viewModel.xpProgress)
                                                .cornerRadius(3)
                                        }
                                    }
                                    .frame(height: 5)
                                    .frame(width: 120)
                                    
                                    Text("\(viewModel.xpToNextLevel) XP to Level \(viewModel.userLevel + 1)")
                                        .font(.system(size: 9, weight: .medium, design: .rounded))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                            }
                            
                            Spacer()
                            
                            // Notifications / Quests
                            Button(action: {}) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.1))
                                        .frame(width: 32, height: 32)
                                    
                                    Image(systemName: "bell.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white)
                                    
                                    if !viewModel.userBadges.isEmpty {
                                        Circle()
                                            .fill(AppColors.error)
                                            .frame(width: 8, height: 8)
                                            .offset(x: 8, y: -8)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 12)
                        
                        // MARK: - War Chest (Budget Overview)
                        if let summary = viewModel.summary {
                            VStack(spacing: 12) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("WAR CHEST")
                                            .font(.system(size: 10, weight: .bold, design: .rounded))
                                            .foregroundColor(AppColors.accent)
                                            .tracking(1)
                                        
                                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                                            Text(viewModel.formatAmount(cents: summary.total_spend_cents))
                                                .font(.system(size: 26, weight: .black, design: .rounded))
                                                .foregroundColor(.white)
                                            
                                            if viewModel.totalBudgetLimit > 0 {
                                                Text("/ \(viewModel.formatAmount(cents: viewModel.totalBudgetLimit))")
                                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                                    .foregroundColor(.white.opacity(0.5))
                                            } else {
                                                Text("spent")
                                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                                    .foregroundColor(.white.opacity(0.5))
                                            }
                                        }
                                    }
                                    Spacer()
                                    Image(systemName: "shield.check.fill")
                                        .font(.system(size: 30))
                                        .foregroundColor(AppColors.accent.opacity(0.3))
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
                                                        ? [AppColors.rare, AppColors.primary, AppColors.accent] 
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
                                    .frame(height: 10)
                                } else {
                                    // No budget set - show prompt
                                    Text("Set a budget to track your progress!")
                                        .font(.system(size: 10, weight: .medium, design: .rounded))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                            }
                            .padding(18)
                            .background(
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.white.opacity(0.08), Color.white.opacity(0.03)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(
                                        LinearGradient(
                                            colors: [AppColors.primary.opacity(0.5), AppColors.accent.opacity(0.3), AppColors.epic.opacity(0.2)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1.5
                                    )
                            )
                            .shadow(color: AppColors.epic.opacity(0.15), radius: 15, y: 5)
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
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 6) {
                                Image(systemName: "cube.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppColors.accent)
                                Text("RESOURCES")
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    if viewModel.categories.isEmpty {
                                        ForEach(0..<3) { _ in
                                            RoundedRectangle(cornerRadius: 14)
                                                .fill(Color.white.opacity(0.05))
                                                .frame(width: 120, height: 110)
                                        }
                                    } else {
                                        ForEach(viewModel.categories.prefix(6), id: \.category) { category in
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
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                HStack(spacing: 6) {
                                    Image(systemName: "shield.lefthalf.filled")
                                        .font(.system(size: 12))
                                        .foregroundColor(AppColors.error)
                                    Text("RECENT BATTLES")
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                }
                                Spacer()
                                NavigationLink(destination: TransactionListView()) {
                                    Text("Full Log")
                                        .font(.system(size: 11, weight: .bold, design: .rounded))
                                        .foregroundColor(AppColors.rare)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .overlay(
                                            Capsule()
                                                .stroke(AppColors.rare.opacity(0.5), lineWidth: 1)
                                        )
                                }
                            }
                            .padding(.horizontal)
                            
                            VStack(spacing: 8) {
                                if viewModel.recentTransactions.isEmpty {
                                    // Empty state
                                    VStack(spacing: 8) {
                                        Image(systemName: "tray")
                                            .font(.system(size: 30))
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
                                    .padding(.vertical, 24)
                                } else {
                                    ForEach(viewModel.recentTransactions.prefix(5), id: \.id) { transaction in
                                        BattleRow(
                                            title: transaction.merchant ?? transaction.category.capitalized,
                                            amount: viewModel.formatAmount(cents: -transaction.total_cents),
                                            date: formatTransactionDate(transaction.txn_date),
                                            isCrit: transaction.total_cents > 10000,
                                            icon: iconForCategory(transaction.category),
                                            color: colorForCategory(transaction.category)
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Padding for TabBar
                        Spacer().frame(height: 80)
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
        case "groceries", "food": return "cart.fill"
        case "dining": return "fork.knife"
        case "transport": return "car.fill"
        case "shopping": return "bag.fill"
        case "entertainment": return "gamecontroller.fill"
        case "subscriptions": return "repeat.circle.fill"
        case "utilities": return "bolt.fill"
        case "health": return "heart.fill"
        case "education": return "book.fill"
        case "travel": return "airplane"
        default: return "ellipsis.circle.fill"
        }
    }
    
    func colorForCategory(_ category: String) -> Color {
        switch category.lowercased() {
        case "groceries", "food": return AppColors.primary
        case "dining": return .orange
        case "transport": return AppColors.rare
        case "shopping": return AppColors.epic
        case "entertainment": return .pink
        case "subscriptions": return AppColors.error
        case "utilities": return AppColors.accent
        case "health": return Color(hex: "#f472b6") ?? .pink
        case "education": return .indigo
        case "travel": return .cyan
        default: return AppColors.info
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
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(color)
            }
            .shadow(color: color.opacity(0.3), radius: 3, y: 1)
            
            Spacer()
            
            Text(title.uppercased())
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundColor(color.opacity(0.9))
                .tracking(0.5)
                .lineLimit(1)
            
            Text(amount)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(14)
        .frame(width: 130, height: 120)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: color.opacity(0.08), radius: 6, y: 2)
    }
}

struct BattleRow: View {
    let title: String
    let amount: String
    let date: String
    let isCrit: Bool
    var icon: String = "sword.fill"
    var color: Color = AppColors.primary
    
    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.18))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(color)
            }
            .shadow(color: color.opacity(0.3), radius: 3, y: 1)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(date)
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.4))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 1) {
                Text(amount)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(color)
                if isCrit {
                    Text("CRIT!")
                        .font(.system(size: 8, weight: .black, design: .rounded))
                        .foregroundColor(AppColors.error)
                        .tracking(1)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isCrit ? AppColors.error.opacity(0.3) : color.opacity(0.1),
                    lineWidth: 1
                )
        )
    }
}

#Preview {
    DashboardView()
}


