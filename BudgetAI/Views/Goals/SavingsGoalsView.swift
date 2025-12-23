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
            let success = await viewModel.createGoal(
                name: name,
                category: nil,
                targetCents: Int(dollars * 100),
                startDate: nil,
                targetDate: nil // Simplified for now
            )
            if success {
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
    
    var body: some View {
        ZStack {
            AppColors.backgroundDark.ignoresSafeArea()
            VStack {
                 // Simplified Detail View
                Text(goal.name).font(AppTypography.h3).foregroundColor(.white)
                // Add more details here as needed
                Spacer()
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
