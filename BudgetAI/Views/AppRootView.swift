//
//  AppRootView.swift
//  testapp
//
//  Main app root view with authentication check
//

import SwiftUI

struct AppRootView: View {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var badgeCelebrationManager = BadgeCelebrationManager.shared
    @StateObject private var pushService = PushNotificationService.shared
    @State private var selectedTab = 0
    @State private var showLogin = false
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                MainTabView(selection: $selectedTab)
                    .sheet(isPresented: $badgeCelebrationManager.showCelebration) {
                        if let badge = badgeCelebrationManager.newBadge {
                            BadgeCelebrationView(
                                badge: badge,
                                isPresented: $badgeCelebrationManager.showCelebration
                            )
                        }
                    }
                    .onChange(of: pushService.pendingNavigation) { destination in
                        if let destination = destination {
                            handleNavigation(destination)
                            pushService.pendingNavigation = nil
                        }
                    }
            } else {
                if showLogin {
                    LoginView()
                        .transition(.move(edge: .trailing))
                } else {
                    WelcomeView(showLogin: $showLogin)
                        .transition(.opacity)
                }
            }
        }
        .task {
            // Check if we have a stored token
            if authManager.isAuthenticated {
                await authManager.refreshUser()
                // Initialize badge celebration manager
                await badgeCelebrationManager.initialize()
            }
        }
    }
    
    private func handleNavigation(_ destination: PushNotificationService.NavigationDestination) {
        switch destination {
        case .budgetAlert:
            selectedTab = 0 // Home
        case .goalDetails:
            selectedTab = 3 // Goals
        case .streak:
            selectedTab = 0 // Home
        case .receipt:
            selectedTab = 1 // Transactions
        }
    }
}

struct MainTabView: View {
    @Binding var selection: Int
    @StateObject private var authManager = AuthManager.shared
    @State private var showingReceiptCapture = false
    @State private var showingManualTransaction = false
    
    var body: some View {
        TabView(selection: $selection) {
            DashboardView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
            
            TransactionListView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Transactions")
                }
                .tag(1)
            
            AddExpenseView()
            .tabItem {
                Image(systemName: "plus.circle.fill")
                Text("Add")
            }
            .tag(2)
            
            SavingsGoalsView()
                .tabItem {
                    Image(systemName: "target")
                    Text("Goals")
                }
                .tag(3)
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(4)
        }
        .accentColor(.blue)
        .sheet(isPresented: $showingReceiptCapture) {
            NavigationView {
                ReceiptCaptureView()
            }
        }
        .sheet(isPresented: $showingManualTransaction) {
            ManualTransactionView()
        }
    }
}

struct AddMenuView: View {
    @Binding var showingReceiptCapture: Bool
    @Binding var showingManualTransaction: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            Button(action: { showingReceiptCapture = true }) {
                VStack(spacing: 12) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 50))
                    Text("Scan Receipt")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            
            Button(action: { showingManualTransaction = true }) {
                VStack(spacing: 12) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 50))
                    Text("Add Manual Transaction")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .navigationTitle("Add Transaction")
    }
}

struct ProfileView: View {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var badgesViewModel = BadgesViewModel()
    @State private var showingLogoutAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    VStack(spacing: 16) {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: 40))
                            )
                        
                        VStack(spacing: 4) {
                            Text(authManager.currentUser?.email ?? "User")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            if let subscription = authManager.subscription {
                                Text(subscription.plan.capitalized)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.top)
                    
                    // Badges
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Badges")
                                .font(.headline)
                            
                            Spacer()
                            
                            NavigationLink(destination: BadgeCollectionView()) {
                                Text("View All")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal)
                        
                        if badgesViewModel.userBadges.isEmpty {
                            Text("No badges earned yet. Start tracking to earn your first badge!")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(badgesViewModel.userBadges.prefix(5), id: \.code) { badge in
                                        BadgeCard(badge: badge)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    // Settings List
                    VStack(spacing: 0) {
                        NavigationLink(destination: BudgetsView()) {
                            SettingsRow(icon: "chart.pie.fill", title: "Budgets", color: .blue)
                        }
                        
                        NavigationLink(destination: BudgetAlertsView()) {
                            SettingsRow(icon: "bell.fill", title: "Alerts", color: .orange)
                        }
                        
                        NavigationLink(destination: UsageView()) {
                            SettingsRow(icon: "chart.bar.fill", title: "Usage", color: .green)
                        }
                        
                        NavigationLink(destination: TagsView()) {
                            SettingsRow(icon: "tag.fill", title: "Tags", color: .purple)
                        }
                        
                        NavigationLink(destination: LinkedAccountsView()) {
                            SettingsRow(icon: "creditcard.fill", title: "Linked Accounts", color: .blue)
                        }
                        
                        NavigationLink(destination: CategoryComparisonView()) {
                            SettingsRow(icon: "chart.bar.xaxis", title: "Category Comparison", color: .orange)
                        }
                        
                        NavigationLink(destination: ReceiptGalleryView()) {
                            SettingsRow(icon: "doc.text.image.fill", title: "Receipt Gallery", color: .blue)
                        }
                        
                        NavigationLink(destination: SettingsView()) {
                            SettingsRow(icon: "gear", title: "Settings", color: .gray)
                        }
                        
                        Button(action: { showingLogoutAlert = true }) {
                            SettingsRow(icon: "arrow.right.square", title: "Logout", color: .red)
                        }
                    }
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Profile")
            .task {
                await badgesViewModel.loadUserBadges()
            }
            .alert("Logout", isPresented: $showingLogoutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Logout", role: .destructive) {
                    Task {
                        try? await authManager.logout()
                    }
                }
            } message: {
                Text("Are you sure you want to logout?")
            }
        }
    }
}

struct BadgeCard: View {
    let badge: UserBadge
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "star.fill")
                .font(.title)
                .foregroundColor(.yellow)
            
            Text(badge.name)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
        }
        .frame(width: 80, height: 100)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(title)
                .font(.body)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.white)
    }
}

struct BudgetsView: View {
    @StateObject private var viewModel = BudgetsViewModel()
    @State private var showingCreateBudget = false
    @State private var editingBudget: BudgetWithSpending?
    
    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.budgets.isEmpty {
                ProgressView()
            } else if let error = viewModel.errorMessage, viewModel.budgets.isEmpty {
                ErrorView(message: error) {
                    Task {
                        await viewModel.loadBudgets()
                    }
                }
            } else if viewModel.budgets.isEmpty {
                EmptyStateView.noBudgets {
                    showingCreateBudget = true
                }
            } else {
                List {
                    ForEach(viewModel.budgets) { budgetWithSpending in
                        BudgetRow(
                            budget: budgetWithSpending,
                            viewModel: viewModel,
                            onEdit: {
                                editingBudget = budgetWithSpending
                            }
                        )
                    }
                    
                    if let error = viewModel.errorMessage {
                        Section {
                            ErrorBanner(
                                message: error,
                                retryAction: {
                                    Task {
                                        await viewModel.loadBudgets()
                                    }
                                },
                                dismissAction: {
                                    viewModel.errorMessage = nil
                                }
                            )
                        }
                    }
                }
            }
        }
        .navigationTitle("Budgets")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Add") {
                    showingCreateBudget = true
                }
            }
        }
        .sheet(isPresented: $showingCreateBudget) {
            CreateBudgetFormView(viewModel: viewModel)
        }
        .sheet(item: $editingBudget) { budget in
            EditBudgetFormView(
                viewModel: viewModel,
                budget: budget.budget
            )
        }
        .refreshable {
            await viewModel.loadBudgets()
        }
        .task {
            await viewModel.loadBudgets()
        }
    }
}

struct BudgetRow: View {
    let budget: BudgetWithSpending
    @ObservedObject var viewModel: BudgetsViewModel
    let onEdit: () -> Void
    
    var progress: Double {
        viewModel.getProgressPercentage(budget: budget)
    }
    
    var progressColor: Color {
        if progress >= 1.0 {
            return .red
        } else if progress >= 0.9 {
            return .orange
        } else {
            return .blue
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(budget.budget.category.capitalized)
                    .font(.headline)
                Spacer()
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .foregroundColor(.blue)
                        .font(.caption)
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
                        .frame(width: geometry.size.width * progress, height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Spent: \(viewModel.formatAmount(cents: budget.spentCents))")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Text("Limit: \(viewModel.formatAmount(cents: budget.budget.limit_cents))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(.headline)
                    .foregroundColor(progressColor)
            }
            
            Text("\(budget.budget.period_start.toDisplayDate()) - \(budget.budget.period_end.toDisplayDate())")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}



struct UsageView: View {
    @StateObject private var usageViewModel = UsageViewModel()
    
    var body: some View {
        List {
            Section("Current Month") {
                HStack {
                    Text("Month")
                    Spacer()
                    Text(usageViewModel.usage?.month_key ?? "-")
                }
                
                HStack {
                    Text("Scans Used")
                    Spacer()
                    Text("\(usageViewModel.usage?.scans_used ?? 0)")
                }
                
                HStack {
                    Text("Scans Remaining")
                    Spacer()
                    if let remaining = usageViewModel.usage?.scans_remaining {
                        Text(remaining == -1 ? "Unlimited" : "\(remaining)")
                    } else {
                        Text("-")
                    }
                }
            }
        }
        .navigationTitle("Usage")
        .task {
            await usageViewModel.loadUsage()
        }
    }
}

#Preview {
    AppRootView()
}
