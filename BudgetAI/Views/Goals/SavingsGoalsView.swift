//
//  SavingsGoalsView.swift
//  BudgetAI
//
//  "Quest Log" / Savings Goals
//

import SwiftUI

struct SavingsGoalsView: View {
    @StateObject private var viewModel = SavingsGoalsViewModel()
    @State private var showingCreateGoal = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.backgroundDark.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Quest Log")
                            .font(AppTypography.h2)
                            .foregroundColor(.white)
                            .shadow(color: AppColors.primary.opacity(0.5), radius: 10)
                        
                        // Total Loot Summary
                        HStack {
                            Image(systemName: "bag.fill.badge.plus")
                                .foregroundColor(AppColors.accent)
                            Text("Total Loot Stashed: \(viewModel.formatAmount(cents: totalSaved))")
                                .font(AppTypography.bodyBold)
                                .foregroundColor(AppColors.accent)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(AppColors.accent.opacity(0.1))
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(AppColors.accent.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .padding(.top, 20)
                    
                    if viewModel.goals.isEmpty {
                        EmptyQuestState(action: { showingCreateGoal = true })
                    } else {
                        ScrollView {
                            VStack(spacing: 16) {
                                ForEach(viewModel.goals, id: \.id) { goal in
                                    NavigationLink(destination: QuestDetailView(goal: goal, viewModel: viewModel)) {
                                        QuestCard(goal: goal, viewModel: viewModel)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    Spacer()
                    
                    // Add Quest Button
                    Button(action: { showingCreateGoal = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("New Quest")
                        }
                        .font(AppTypography.bodyBold)
                        .foregroundColor(AppColors.backgroundDark)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(AppColors.primary)
                        .cornerRadius(12)
                        .shadow(color: AppColors.primary.opacity(0.5), radius: 10)
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingCreateGoal) {
                CreateQuestView(viewModel: viewModel)
            }
            .task {
                await viewModel.loadGoals()
            }
        }
    }
    
    var totalSaved: Int {
        viewModel.goals.reduce(0) { $0 + ($1.contributed_cents ?? 0) }
    }
}

// MARK: - Subcomponents

struct QuestCard: View {
    let goal: SavingsGoal
    let viewModel: SavingsGoalsViewModel
    
    var progress: Double {
        viewModel.progressPercentage(goal: goal)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(AppColors.epic.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "flag.fill")
                        .foregroundColor(AppColors.epic)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.name)
                        .font(AppTypography.bodyBold)
                        .foregroundColor(.white)
                    
                    Text("Target: \(viewModel.formatAmount(cents: goal.target_cents))")
                        .font(AppTypography.small)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                // Badge or Icon based on progress
                if progress >= 100 {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(AppColors.accent)
                        .font(.title2)
                }
            }
            
            // Progress Bar
            VStack(alignment: .leading, spacing: 4) {
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.black.opacity(0.3))
                            .cornerRadius(4)
                        
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [AppColors.success, AppColors.primary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: g.size.width * CGFloat(min(progress, 100.0) / 100.0))
                            .cornerRadius(4)
                            .shadow(color: AppColors.primary.opacity(0.5), radius: 5)
                    }
                }
                .frame(height: 8)
                
                HStack {
                    Text("\(Int(progress))% Complete")
                        .font(AppTypography.small)
                        .foregroundColor(AppColors.primary)
                    
                    Spacer()
                    
                    Text("\(viewModel.formatAmount(cents: goal.contributed_cents ?? 0)) Saved")
                        .font(AppTypography.small)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(progress >= 100 ? AppColors.accent : Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

struct EmptyQuestState: View {
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "scroll.fill")
                .font(.system(size: 60))
                .foregroundColor(AppColors.textSecondary)
                .opacity(0.5)
            
            Text("No Quests Active")
                .font(AppTypography.h4)
                .foregroundColor(.white)
            
            Text("Start a new savings quest to earn loot!")
                .font(AppTypography.body)
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding()
    }
}

struct CreateQuestView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: SavingsGoalsViewModel
    @State private var name = ""
    @State private var targetDollars = ""
    @State private var targetDate: Date = Date()
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            AppColors.backgroundDark.ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text("New Quest")
                    .font(AppTypography.h3)
                    .foregroundColor(.white)
                    .padding(.top)
                
                VStack(spacing: 16) {
                    GamifiedTextField(text: $name, placeholder: "Quest Name (e.g. New Sword)", icon: "tag.fill")
                    GamifiedTextField(text: $targetDollars, placeholder: "Target Loot ($)", icon: "dollarsign.circle.fill", keyboardType: .decimalPad)
                    
                    // Date Picker Override
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(AppColors.primary)
                        DatePicker("Target Date", selection: $targetDate, displayedComponents: .date)
                            .colorScheme(.dark)
                    }
                    .padding()
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1)))
                }
                .padding()
                
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(AppColors.error)
                        .font(AppTypography.small)
                }
                
                Button(action: createGoal) {
                    Text("Embark on Quest")
                        .font(AppTypography.bodyBold)
                        .foregroundColor(AppColors.backgroundDark)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(AppColors.primary)
                        .cornerRadius(12)
                        .shadow(color: AppColors.primary.opacity(0.5), radius: 10)
                }
                .padding(.horizontal)
                
                Spacer()
            }
        }
    }
    
    private func createGoal() {
        guard let dollars = Double(targetDollars), dollars > 0, !name.isEmpty else {
            errorMessage = "Please enter valid quest details."
            return
        }
        
        Task {
            await viewModel.createGoal(
                name: name,
                category: nil,
                targetCents: Int(dollars * 100),
                startDate: nil,
                targetDate: nil // Simplified for now
            )
            if viewModel.errorMessage == nil {
                dismiss()
            } else {
                errorMessage = viewModel.errorMessage
            }
        }
    }
}

// Reimplementing this briefly to support navigation
struct QuestDetailView: View {
    let goal: SavingsGoal
    @ObservedObject var viewModel: SavingsGoalsViewModel
    @State private var showingContribute = false
    @State private var contributionAmount = ""
    @State private var contributionNote = ""
    @Environment(\.dismiss) private var dismiss
    
    var progressPercentage: Double {
        guard goal.target_cents > 0 else { return 0 }
        return min(1.0, Double(goal.contributed_cents ?? 0) / Double(goal.target_cents))
    }
    
    var body: some View {
        ZStack {
            AppColors.backgroundDark.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Quest Banner
                    VStack(spacing: 16) {
                        // Icon
                        ZStack {
                            Circle()
                                .fill(AppColors.epic.opacity(0.2))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "flag.fill")
                                .font(.system(size: 36))
                                .foregroundColor(AppColors.epic)
                        }
                        
                        Text(goal.name)
                            .font(AppTypography.h2)
                            .foregroundColor(.white)
                        
                        if let category = goal.category {
                            Text(category.capitalized)
                                .font(AppTypography.caption)
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(12)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Progress Card
                    VStack(spacing: 16) {
                        HStack {
                            Text("QUEST PROGRESS")
                                .font(AppTypography.small)
                                .foregroundColor(AppColors.primary)
                                .tracking(1)
                            Spacer()
                            Text("\(Int(progressPercentage * 100))%")
                                .font(AppTypography.h4)
                                .foregroundColor(AppColors.primary)
                        }
                        
                        // Progress Bar
                        GeometryReader { g in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.black.opacity(0.3))
                                    .cornerRadius(8)
                                
                                Rectangle()
                                    .fill(LinearGradient(
                                        colors: [AppColors.primary, AppColors.epic],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ))
                                    .frame(width: g.size.width * progressPercentage)
                                    .cornerRadius(8)
                            }
                        }
                        .frame(height: 12)
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Saved")
                                    .font(AppTypography.small)
                                    .foregroundColor(.white.opacity(0.6))
                                Text(viewModel.formatAmount(cents: goal.contributed_cents ?? 0))
                                    .font(AppTypography.h4)
                                    .foregroundColor(AppColors.primary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text("Target")
                                    .font(AppTypography.small)
                                    .foregroundColor(.white.opacity(0.6))
                                Text(viewModel.formatAmount(cents: goal.target_cents))
                                    .font(AppTypography.h4)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.05))
                    )
                    .padding(.horizontal)
                    
                    // Quest Info
                    VStack(spacing: 12) {
                        if let targetDate = goal.target_date {
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(AppColors.accent)
                                Text("Target Date")
                                    .foregroundColor(.white.opacity(0.6))
                                Spacer()
                                Text(formatDate(targetDate))
                                    .foregroundColor(.white)
                            }
                            .font(AppTypography.body)
                        }
                        
                        HStack {
                            Image(systemName: "flag.checkered")
                                .foregroundColor(AppColors.primary)
                            Text("Status")
                                .foregroundColor(.white.opacity(0.6))
                            Spacer()
                            Text(goal.status.capitalized)
                                .foregroundColor(goal.status == "completed" ? AppColors.success : AppColors.primary)
                        }
                        .font(AppTypography.body)
                        
                        let remaining = goal.target_cents - (goal.contributed_cents ?? 0)
                        if remaining > 0 {
                            HStack {
                                Image(systemName: "dollarsign.circle")
                                    .foregroundColor(AppColors.accent)
                                Text("Remaining")
                                    .foregroundColor(.white.opacity(0.6))
                                Spacer()
                                Text(viewModel.formatAmount(cents: remaining))
                                    .foregroundColor(AppColors.accent)
                            }
                            .font(AppTypography.body)
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.05))
                    )
                    .padding(.horizontal)
                    
                    // Add Contribution Button
                    Button(action: { showingContribute = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Loot")
                        }
                        .font(AppTypography.bodyBold)
                        .foregroundColor(AppColors.backgroundDark)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(AppColors.primary)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    Spacer().frame(height: 50)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingContribute) {
            ContributeSheet(
                goal: goal,
                viewModel: viewModel,
                isPresented: $showingContribute
            )
        }
    }
    
    func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: dateString) {
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
        return dateString
    }
}

struct ContributeSheet: View {
    let goal: SavingsGoal
    @ObservedObject var viewModel: SavingsGoalsViewModel
    @Binding var isPresented: Bool
    @State private var amount = ""
    @State private var note = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.backgroundDark.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Text("Add to \(goal.name)")
                        .font(AppTypography.h3)
                        .foregroundColor(.white)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Amount")
                            .font(AppTypography.caption)
                            .foregroundColor(.white.opacity(0.6))
                        
                        HStack {
                            Text("$")
                                .foregroundColor(AppColors.primary)
                            TextField("0.00", text: $amount)
                                .keyboardType(.decimalPad)
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(12)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Note (optional)")
                            .font(AppTypography.caption)
                            .foregroundColor(.white.opacity(0.6))
                        
                        TextField("e.g., Birthday money", text: $note)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(12)
                    }
                    
                    if let error = errorMessage {
                        Text(error)
                            .font(AppTypography.small)
                            .foregroundColor(AppColors.error)
                    }
                    
                    Spacer()
                    
                    Button(action: contribute) {
                        if isLoading {
                            ProgressView()
                                .tint(AppColors.backgroundDark)
                        } else {
                            Text("Add Loot")
                                .font(AppTypography.bodyBold)
                        }
                    }
                    .foregroundColor(AppColors.backgroundDark)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppColors.primary)
                    .cornerRadius(12)
                    .disabled(isLoading || amount.isEmpty)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(AppColors.primary)
                }
            }
        }
    }
    
    func contribute() {
        guard let amountDouble = Double(amount), amountDouble > 0 else {
            errorMessage = "Please enter a valid amount"
            return
        }
        
        let cents = Int(amountDouble * 100)
        isLoading = true
        errorMessage = nil
        
        Task {
            await viewModel.addContribution(
                goalId: goal.id,
                amountCents: cents,
                note: note.isEmpty ? nil : note
            )
            isLoading = false
            
            if viewModel.errorMessage == nil {
                isPresented = false
            } else {
                errorMessage = viewModel.errorMessage
            }
        }
    }
}

struct GamifiedTextField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(AppColors.primary)
                .frame(width: 24)
            
            TextField(placeholder, text: $text)
                .foregroundColor(.white)
                .keyboardType(keyboardType)
                .placeholder(when: text.isEmpty) {
                    Text(placeholder).foregroundColor(.white.opacity(0.3))
                }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {

        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

// Re-defining this to avoid compilation errors if it's used elsewhere or logic needed
struct SavingsContribution: Codable {
    let id: String
    let goal_id: String
    let amount_cents: Int
    let note: String?
    let contributed_at: String
}
