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
                LoginView()
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
            
            AddMenuView(
                showingReceiptCapture: $showingReceiptCapture,
                showingManualTransaction: $showingManualTransaction
            )
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


struct SavingsGoalsView: View {
    @StateObject private var viewModel = SavingsGoalsViewModel()
    @State private var showingCreateGoal = false
    
    var body: some View {
        NavigationView {
            if viewModel.isLoading && viewModel.goals.isEmpty {
                ProgressView()
            } else if viewModel.goals.isEmpty {
                EmptyStateView.noSavingsGoals {
                    showingCreateGoal = true
                }
            } else {
                List {
                    ForEach(viewModel.goals, id: \.id) { goal in
                    NavigationLink(destination: SavingsGoalDetailView(goal: goal, viewModel: viewModel)) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(goal.name)
                                .font(.headline)
                            
                            HStack {
                                Text("\(viewModel.formatAmount(cents: goal.contributed_cents ?? 0)) / \(viewModel.formatAmount(cents: goal.target_cents))")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text("\(Int(viewModel.progressPercentage(goal: goal)))%")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 8)
                                        .cornerRadius(4)
                                    
                                    Rectangle()
                                        .fill(Color.green)
                                        .frame(
                                            width: geometry.size.width * CGFloat(viewModel.progressPercentage(goal: goal) / 100.0),
                                            height: 8
                                        )
                                        .cornerRadius(4)
                                }
                            }
                            .frame(height: 8)
                        }
                        .padding(.vertical, 4)
                    }
                }
                }
            .navigationTitle("Savings Goals")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        showingCreateGoal = true
                    }
                }
            }
            .sheet(isPresented: $showingCreateGoal) {
                CreateSavingsGoalView(viewModel: viewModel)
            }
            .task {
                await viewModel.loadGoals()
            }
        }
    }
}

struct SavingsGoalDetailView: View {
    let goal: SavingsGoal
    @ObservedObject var viewModel: SavingsGoalsViewModel
    @State private var showingAddContribution = false
    @State private var showingEdit = false
    @State private var showingDeleteAlert = false
    @State private var showingShareSheet = false
    @State private var shareItems: [Any] = []
    @State private var goalDetails: SavingsGoal?
    @State private var contributions: [SavingsContribution] = []
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text(goalDetails?.name ?? goal.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    HStack {
                        Text("Target: \(viewModel.formatAmount(cents: goalDetails?.target_cents ?? goal.target_cents))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if let contributed = goalDetails?.contributed_cents ?? goal.contributed_cents {
                            Text("Saved: \(viewModel.formatAmount(cents: contributed))")
                                .font(.subheadline)
                                .foregroundColor(.green)
                                .fontWeight(.medium)
                        }
                    }
                    
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 12)
                                .cornerRadius(6)
                            
                            Rectangle()
                                .fill(Color.green)
                                .frame(
                                    width: geometry.size.width * CGFloat(progressPercentage / 100.0),
                                    height: 12
                                )
                                .cornerRadius(6)
                        }
                    }
                    .frame(height: 12)
                    
                    if let targetDate = goalDetails?.target_date ?? goal.target_date {
                        Text("Target Date: \(targetDate.toDisplayDate())")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }
            
            Section("Contributions") {
                if contributions.isEmpty {
                    Text("No contributions yet")
                        .foregroundColor(.secondary)
                        .font(.caption)
                } else {
                    ForEach(contributions, id: \.id) { contribution in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(viewModel.formatAmount(cents: contribution.amount_cents))
                                    .font(.headline)
                                Spacer()
                                Text(contribution.contributed_at.toDisplayDate())
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            if let note = contribution.note, !note.isEmpty {
                                Text(note)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Button(action: { showingAddContribution = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Contribution")
                    }
                    .foregroundColor(.blue)
                }
            }
            
            Section {
                Button(action: { showingEdit = true }) {
                    HStack {
                        Image(systemName: "pencil")
                        Text("Edit Goal")
                    }
                    .foregroundColor(.blue)
                }
                
                if goalDetails?.status ?? goal.status == "active" {
                    Button(action: { showingDeleteAlert = true }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Goal")
                        }
                        .foregroundColor(.red)
                    }
                }
            }
        }
        .navigationTitle("Goal Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    shareGoal()
                }) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: shareItems)
        }
        .sheet(isPresented: $showingAddContribution) {
            AddContributionView(goalId: goal.id, viewModel: viewModel)
        }
        .sheet(isPresented: $showingEdit) {
            EditSavingsGoalView(goal: goalDetails ?? goal, viewModel: viewModel)
        }
        .alert("Delete Goal", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteGoal(id: goal.id)
                    dismiss()
                }
            }
        } message: {
            Text("Are you sure you want to delete this goal? This action cannot be undone.")
        }
        .task {
            await loadGoalDetails()
        }
    }
    
    private var progressPercentage: Double {
        guard let contributed = goalDetails?.contributed_cents ?? goal.contributed_cents,
              let target = goalDetails?.target_cents ?? goal.target_cents,
              target > 0 else {
            return 0
        }
        return min(100.0, (Double(contributed) / Double(target)) * 100.0)
    }
    
    private func shareGoal() {
        let goalName = goalDetails?.name ?? goal.name
        let contributed = goalDetails?.contributed_cents ?? goal.contributed_cents ?? 0
        let target = goalDetails?.target_cents ?? goal.target_cents
        let progress = Int(progressPercentage)
        
        let text = "💰 I'm saving for \(goalName)! Progress: \(viewModel.formatAmount(cents: contributed)) / \(viewModel.formatAmount(cents: target)) (\(progress)%) #SnapBudget"
        shareItems = [text]
        showingShareSheet = true
    }
    
    private func loadGoalDetails() async {
        if let details = await viewModel.getGoal(id: goal.id) {
            goalDetails = details
            // Load contributions from goal details if available
            // Note: Backend returns contributions in the goal details response
        }
    }
}

struct SavingsContribution: Codable {
    let id: String
    let goal_id: String
    let amount_cents: Int
    let note: String?
    let contributed_at: String
}

struct CreateSavingsGoalView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: SavingsGoalsViewModel
    @State private var name = ""
    @State private var targetDollars = ""
    @State private var targetDate: Date?
    @State private var showingDatePicker = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            Form {
                Section("Goal Details") {
                    TextField("Goal Name", text: $name)
                    
                    TextField("Target Amount ($)", text: $targetDollars)
                        .keyboardType(.decimalPad)
                }
                
                Section("Target Date (Optional)") {
                    if let date = targetDate {
                        HStack {
                            Text("Target Date")
                            Spacer()
                            Text(date.toDisplayString())
                                .foregroundColor(.secondary)
                            Button("Clear") {
                                targetDate = nil
                            }
                            .font(.caption)
                            .foregroundColor(.red)
                        }
                    } else {
                        Button("Set Target Date") {
                            showingDatePicker = true
                        }
                    }
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveGoal()
                    }
                    .disabled(name.isEmpty || targetDollars.isEmpty || !isValid)
                }
            }
            .sheet(isPresented: $showingDatePicker) {
                DatePickerSheet(selectedDate: $targetDate)
            }
        }
    }
    
    private var isValid: Bool {
        guard let target = Double(targetDollars), target > 0 else { return false }
        return true
    }
    
    private func saveGoal() {
        guard let target = Double(targetDollars), target > 0 else {
            errorMessage = "Please enter a valid amount"
            return
        }
        
        errorMessage = nil
        
        Task {
            await viewModel.createGoal(
                name: name,
                category: nil,
                targetCents: Int(target * 100),
                startDate: nil,
                targetDate: targetDate?.toInputString()
            )
            dismiss()
        }
    }
}

struct DatePickerSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedDate: Date?
    @State private var tempDate = Date()
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker("Select Date", selection: $tempDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Target Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        selectedDate = tempDate
                        dismiss()
                    }
                }
            }
        }
    }
}

struct EditSavingsGoalView: View {
    @Environment(\.dismiss) var dismiss
    let goal: SavingsGoal
    @ObservedObject var viewModel: SavingsGoalsViewModel
    
    @State private var name: String
    @State private var targetDollars: String
    @State private var targetDate: Date?
    @State private var showingDatePicker = false
    @State private var errorMessage: String?
    
    init(goal: SavingsGoal, viewModel: SavingsGoalsViewModel) {
        self.goal = goal
        self.viewModel = viewModel
        _name = State(initialValue: goal.name)
        _targetDollars = State(initialValue: String(format: "%.2f", Double(goal.target_cents) / 100.0))
        _targetDate = State(initialValue: goal.target_date?.toDate())
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Goal Details") {
                    TextField("Goal Name", text: $name)
                    
                    TextField("Target Amount ($)", text: $targetDollars)
                        .keyboardType(.decimalPad)
                }
                
                Section("Target Date (Optional)") {
                    if let date = targetDate {
                        HStack {
                            Text("Target Date")
                            Spacer()
                            Text(date.toDisplayString())
                                .foregroundColor(.secondary)
                            Button("Clear") {
                                targetDate = nil
                            }
                            .font(.caption)
                            .foregroundColor(.red)
                        }
                    } else {
                        Button("Set Target Date") {
                            showingDatePicker = true
                        }
                    }
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Edit Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveGoal()
                    }
                    .disabled(name.isEmpty || targetDollars.isEmpty || !isValid)
                }
            }
            .sheet(isPresented: $showingDatePicker) {
                DatePickerSheet(selectedDate: $targetDate)
            }
        }
    }
    
    private var isValid: Bool {
        guard let target = Double(targetDollars), target > 0 else { return false }
        return true
    }
    
    private func saveGoal() {
        guard let target = Double(targetDollars), target > 0 else {
            errorMessage = "Please enter a valid amount"
            return
        }
        
        errorMessage = nil
        
        Task {
            await viewModel.updateGoal(
                id: goal.id,
                name: name,
                targetCents: Int(target * 100),
                targetDate: targetDate?.toInputString()
            )
            dismiss()
        }
    }
}

struct AddContributionView: View {
    @Environment(\.dismiss) var dismiss
    let goalId: String
    @ObservedObject var viewModel: SavingsGoalsViewModel
    @State private var amountDollars = ""
    @State private var note = ""
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            Form {
                Section("Contribution") {
                    TextField("Amount ($)", text: $amountDollars)
                        .keyboardType(.decimalPad)
                    
                    TextField("Note (optional)", text: $note)
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Add Contribution")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveContribution()
                    }
                    .disabled(amountDollars.isEmpty || !isValid)
                }
            }
        }
    }
    
    private var isValid: Bool {
        guard let amount = Double(amountDollars), amount > 0 else { return false }
        return true
    }
    
    private func saveContribution() {
        guard let amount = Double(amountDollars), amount > 0 else {
            errorMessage = "Please enter a valid amount"
            return
        }
        
        errorMessage = nil
        
        Task {
            await viewModel.addContribution(
                goalId: goalId,
                amountCents: Int(amount * 100),
                note: note.isEmpty ? nil : note
            )
            dismiss()
        }
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
