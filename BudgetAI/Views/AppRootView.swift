//
//  AppRootView.swift
//  BudgetAI
//
//  Main app root view with authentication check
//

import SwiftUI

struct AppRootView: View {
    @ObservedObject private var authManager = AuthManager.shared
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
    @ObservedObject private var authManager = AuthManager.shared
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
    @ObservedObject private var authManager = AuthManager.shared
    @StateObject private var badgesViewModel = BadgesViewModel()
    @State private var showingLogoutAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.backgroundDark.ignoresSafeArea()
                
                // Background glows
                VStack {
                    Circle()
                        .fill(AppColors.epic.opacity(0.08))
                        .frame(width: 300, height: 300)
                        .blur(radius: 100)
                        .offset(x: -120, y: -180)
                    Spacer()
                }
                VStack {
                    Spacer()
                    Circle()
                        .fill(AppColors.rare.opacity(0.06))
                        .frame(width: 250, height: 250)
                        .blur(radius: 80)
                        .offset(x: 140, y: 40)
                }
                VStack {
                    Circle()
                        .fill(AppColors.primary.opacity(0.05))
                        .frame(width: 200, height: 200)
                        .blur(radius: 70)
                        .offset(x: 80, y: 100)
                    Spacer()
                }
                
                ScrollView {
                    VStack(spacing: 16) {
                        // MARK: - Header
                        profileHeader
                        
                        // MARK: - Player Card
                        playerCard
                        
                        // MARK: - Badges
                        badgesSection
                        
                        // MARK: - Menu
                        menuSection
                        
                        // MARK: - Logout
                        logoutButton
                        
                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 16)
                }
            }
            .navigationBarHidden(true)
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
    
    // MARK: - Profile Header
    private var profileHeader: some View {
        HStack {
            Image(systemName: "person.text.rectangle.fill")
                .font(.system(size: 14))
                .foregroundColor(AppColors.epic)
            Text("PLAYER PROFILE")
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .tracking(2)
            Spacer()
        }
        .padding(.top, 8)
    }
    
    // MARK: - Player Card
    private var playerCard: some View {
        HStack(spacing: 14) {
            // Avatar
            ZStack {
                Circle()
                    .stroke(LinearGradient(colors: [AppColors.accent, AppColors.epic, AppColors.rare], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 2.5)
                    .frame(width: 56, height: 56)
                
                Image(systemName: "person.fill")
                    .font(.system(size: 24))
                    .foregroundColor(AppColors.accent)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(authManager.currentUser?.email ?? "Player")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                if let subscription = authManager.subscription {
                    HStack(spacing: 4) {
                        Image(systemName: subscription.plan == "free" ? "shield" : "shield.checkered")
                            .font(.system(size: 10))
                        Text(subscription.plan.uppercased())
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .tracking(1)
                    }
                    .foregroundColor(subscription.plan == "free" ? AppColors.rare : AppColors.legendary)
                }
            }
            
            Spacer()
            
            // Badge count
            VStack(spacing: 2) {
                Text("\(badgesViewModel.userBadges.count)")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundColor(AppColors.accent)
                Text("BADGES")
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.5))
                    .tracking(1)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(LinearGradient(colors: [AppColors.epic.opacity(0.4), AppColors.rare.opacity(0.2), Color.clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Badges Section
    private var badgesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.accent)
                Text("TROPHIES")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.7))
                    .tracking(1.5)
                
                Spacer()
                
                NavigationLink(destination: BadgeCollectionView()) {
                    HStack(spacing: 3) {
                        Text("View All")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .foregroundColor(AppColors.epic)
                }
            }
            
            if badgesViewModel.userBadges.isEmpty {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(AppColors.accent.opacity(0.5))
                    Text("No trophies yet — start your quest!")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.4))
                }
                .padding(.vertical, 10)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(badgesViewModel.userBadges.prefix(6), id: \.code) { badge in
                            BadgeCard(badge: badge)
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Menu Section
    private var menuSection: some View {
        VStack(spacing: 1) {
            NavigationLink(destination: BudgetsView()) {
                SettingsRow(icon: "chart.pie.fill", title: "Budgets", color: AppColors.rare)
            }
            NavigationLink(destination: BudgetAlertsView()) {
                SettingsRow(icon: "bell.badge.fill", title: "Alerts", color: AppColors.accent)
            }
            NavigationLink(destination: UsageView()) {
                SettingsRow(icon: "flame.fill", title: "Usage", color: AppColors.primary)
            }
            NavigationLink(destination: TagsView()) {
                SettingsRow(icon: "tag.fill", title: "Tags", color: AppColors.epic)
            }
            NavigationLink(destination: LinkedAccountsView()) {
                SettingsRow(icon: "link.circle.fill", title: "Linked Accounts", color: AppColors.rare)
            }
            NavigationLink(destination: CategoryComparisonView()) {
                SettingsRow(icon: "chart.bar.xaxis", title: "Category Comparison", color: Color.orange)
            }
            NavigationLink(destination: ReceiptGalleryView()) {
                SettingsRow(icon: "photo.stack.fill", title: "Receipt Gallery", color: AppColors.info)
            }
            NavigationLink(destination: SettingsView()) {
                SettingsRow(icon: "gearshape.fill", title: "Settings", color: Color.white.opacity(0.5))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
    
    // MARK: - Logout Button
    private var logoutButton: some View {
        Button(action: { showingLogoutAlert = true }) {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 14, weight: .semibold))
                Text("LOGOUT")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .tracking(1)
            }
            .foregroundColor(AppColors.error)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.error.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppColors.error.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
}

struct BadgeCard: View {
    let badge: UserBadge
    
    private var badgeIcon: String {
        let code = badge.code.lowercased()
        if code.contains("streak") { return "flame.fill" }
        if code.contains("sav") { return "shield.checkered" }
        if code.contains("budget") { return "chart.pie.fill" }
        if code.contains("receipt") || code.contains("scan") { return "doc.text.viewfinder" }
        if code.contains("first") { return "star.circle.fill" }
        return "trophy.fill"
    }
    
    private var badgeColor: Color {
        let code = badge.code.lowercased()
        if code.contains("streak") { return Color.orange }
        if code.contains("sav") { return AppColors.primary }
        if code.contains("budget") { return AppColors.rare }
        if code.contains("receipt") || code.contains("scan") { return AppColors.epic }
        return AppColors.accent
    }
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(badgeColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: badgeIcon)
                    .font(.system(size: 18))
                    .foregroundColor(badgeColor)
            }
            
            Text(badge.name)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(width: 70, height: 78)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(badgeColor.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 7)
                    .fill(color.opacity(0.15))
                    .frame(width: 30, height: 30)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(Color.white.opacity(0.25))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.03))
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
        .refreshable {
            await usageViewModel.loadUsage()
        }
        .onAppear {
            Task {
                await usageViewModel.loadUsage()
            }
        }
    }
}

#Preview {
    AppRootView()
}
