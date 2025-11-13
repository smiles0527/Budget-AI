//
//  AppRootView.swift
//  testapp
//
//  Main app root view with authentication check
//

import SwiftUI

struct AppRootView: View {
    @StateObject private var authManager = AuthManager.shared
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .task {
            // Check if we have a stored token
            if authManager.isAuthenticated {
                await authManager.refreshUser()
            }
        }
    }
}

struct MainTabView: View {
    @StateObject private var authManager = AuthManager.shared
    @State private var showingReceiptCapture = false
    
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            
            TransactionListView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Transactions")
                }
            
            Button(action: { showingReceiptCapture = true }) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 30))
            }
            .tabItem {
                Image(systemName: "plus.circle.fill")
                Text("Add")
            }
            
            SavingsGoalsView()
                .tabItem {
                    Image(systemName: "target")
                    Text("Goals")
                }
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
        }
        .accentColor(.blue)
        .sheet(isPresented: $showingReceiptCapture) {
            NavigationView {
                ReceiptCaptureView()
            }
        }
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
                    if !badgesViewModel.userBadges.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Badges")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(badgesViewModel.userBadges, id: \.code) { badge in
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
                        
                        NavigationLink(destination: UsageView()) {
                            SettingsRow(icon: "chart.bar.fill", title: "Usage", color: .green)
                        }
                        
                        SettingsRow(icon: "bell.fill", title: "Notifications", color: .orange)
                        
                        SettingsRow(icon: "gear", title: "Settings", color: .gray)
                        
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
    
    var body: some View {
        List {
            ForEach(viewModel.budgets, id: \.id) { budget in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(budget.category.capitalized)
                            .font(.headline)
                        Spacer()
                        Text(viewModel.formatAmount(cents: budget.limit_cents))
                            .font(.headline)
                    }
                    
                    Text("\(budget.period_start) to \(budget.period_end)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
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
            CreateBudgetView(viewModel: viewModel)
        }
        .task {
            await viewModel.loadBudgets()
        }
    }
}

struct CreateBudgetView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: BudgetsViewModel
    @State private var category = "groceries"
    @State private var limitDollars = ""
    @State private var periodStart = ""
    @State private var periodEnd = ""
    
    let categories = ["groceries", "dining", "transport", "shopping", "entertainment", "subscriptions", "utilities", "health", "education", "travel", "other"]
    
    var body: some View {
        NavigationView {
            Form {
                Picker("Category", selection: $category) {
                    ForEach(categories, id: \.self) { cat in
                        Text(cat.capitalized).tag(cat)
                    }
                }
                
                TextField("Limit ($)", text: $limitDollars)
                    .keyboardType(.decimalPad)
                
                TextField("Start Date (YYYY-MM-DD)", text: $periodStart)
                
                TextField("End Date (YYYY-MM-DD)", text: $periodEnd)
            }
            .navigationTitle("New Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if let limit = Double(limitDollars) {
                            Task {
                                await viewModel.createBudget(
                                    periodStart: periodStart,
                                    periodEnd: periodEnd,
                                    category: category,
                                    limitCents: Int(limit * 100)
                                )
                                dismiss()
                            }
                        }
                    }
                }
            }
        }
    }
}

struct SavingsGoalsView: View {
    @StateObject private var viewModel = SavingsGoalsViewModel()
    @State private var showingCreateGoal = false
    
    var body: some View {
        NavigationView {
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
    @State private var contributionAmount = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(goal.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Target: \(viewModel.formatAmount(cents: goal.target_cents))")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    
                    if let contributed = goal.contributed_cents {
                        Text("Saved: \(viewModel.formatAmount(cents: contributed))")
                            .font(.title2)
                            .foregroundColor(.green)
                    }
                }
                .padding()
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 20)
                            .cornerRadius(10)
                        
                        Rectangle()
                            .fill(Color.green)
                            .frame(
                                width: geometry.size.width * CGFloat(viewModel.progressPercentage(goal: goal) / 100.0),
                                height: 20
                            )
                            .cornerRadius(10)
                    }
                }
                .frame(height: 20)
                .padding(.horizontal)
                
                Button("Add Contribution") {
                    showingAddContribution = true
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
            }
        }
        .navigationTitle("Goal")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddContribution) {
            AddContributionView(goalId: goal.id, viewModel: viewModel)
        }
    }
}

struct CreateSavingsGoalView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: SavingsGoalsViewModel
    @State private var name = ""
    @State private var targetDollars = ""
    @State private var targetDate = ""
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Goal Name", text: $name)
                
                TextField("Target Amount ($)", text: $targetDollars)
                    .keyboardType(.decimalPad)
                
                TextField("Target Date (YYYY-MM-DD)", text: $targetDate)
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
                        if let target = Double(targetDollars) {
                            Task {
                                await viewModel.createGoal(
                                    name: name,
                                    category: nil,
                                    targetCents: Int(target * 100),
                                    startDate: nil,
                                    targetDate: targetDate.isEmpty ? nil : targetDate
                                )
                                dismiss()
                            }
                        }
                    }
                }
            }
        }
    }
}

struct AddContributionView: View {
    @Environment(\.dismiss) var dismiss
    let goalId: String
    @ObservedObject var viewModel: SavingsGoalsViewModel
    @State private var amountDollars = ""
    @State private var note = ""
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Amount ($)", text: $amountDollars)
                    .keyboardType(.decimalPad)
                
                TextField("Note (optional)", text: $note)
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
                        if let amount = Double(amountDollars) {
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
                }
            }
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
