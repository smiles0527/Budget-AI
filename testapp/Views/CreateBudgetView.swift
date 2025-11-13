//
//  CreateBudgetView.swift
//  testapp
//
//  Create budget form with date pickers
//

import SwiftUI

struct CreateBudgetFormView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: BudgetsViewModel
    @State private var category = "groceries"
    @State private var limitDollars = ""
    @State private var periodStart = Date()
    @State private var periodEnd = Date()
    @State private var errorMessage: String?
    
    let categories = ["groceries", "dining", "transport", "shopping", "entertainment", "subscriptions", "utilities", "health", "education", "travel", "other"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Budget Details") {
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat.capitalized).tag(cat)
                        }
                    }
                    
                    TextField("Monthly Limit ($)", text: $limitDollars)
                        .keyboardType(.decimalPad)
                }
                
                Section("Period") {
                    DatePicker("Start Date", selection: $periodStart, displayedComponents: .date)
                    DatePicker("End Date", selection: $periodEnd, displayedComponents: .date)
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
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
                        saveBudget()
                    }
                    .disabled(limitDollars.isEmpty || !isValid)
                }
            }
        }
    }
    
    private var isValid: Bool {
        guard let limit = Double(limitDollars), limit > 0 else { return false }
        return periodEnd >= periodStart
    }
    
    private func saveBudget() {
        guard let limit = Double(limitDollars), limit > 0 else {
            errorMessage = "Please enter a valid amount"
            return
        }
        
        guard periodEnd >= periodStart else {
            errorMessage = "End date must be after start date"
            return
        }
        
        errorMessage = nil
        
        Task {
            await viewModel.createBudget(
                periodStart: periodStart.toInputString(),
                periodEnd: periodEnd.toInputString(),
                category: category,
                limitCents: Int(limit * 100)
            )
            dismiss()
        }
    }
}

struct EditBudgetFormView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: BudgetsViewModel
    let budget: Budget
    
    @State private var category: String
    @State private var limitDollars: String
    @State private var periodStart: Date
    @State private var periodEnd: Date
    @State private var errorMessage: String?
    
    let categories = ["groceries", "dining", "transport", "shopping", "entertainment", "subscriptions", "utilities", "health", "education", "travel", "other"]
    
    init(viewModel: BudgetsViewModel, budget: Budget) {
        self.viewModel = viewModel
        self.budget = budget
        _category = State(initialValue: budget.category)
        _limitDollars = State(initialValue: String(format: "%.2f", Double(budget.limit_cents) / 100.0))
        _periodStart = State(initialValue: budget.period_start.toDate() ?? Date())
        _periodEnd = State(initialValue: budget.period_end.toDate() ?? Date())
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Budget Details") {
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat.capitalized).tag(cat)
                        }
                    }
                    
                    TextField("Monthly Limit ($)", text: $limitDollars)
                        .keyboardType(.decimalPad)
                }
                
                Section("Period") {
                    DatePicker("Start Date", selection: $periodStart, displayedComponents: .date)
                    DatePicker("End Date", selection: $periodEnd, displayedComponents: .date)
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Edit Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveBudget()
                    }
                    .disabled(limitDollars.isEmpty || !isValid)
                }
            }
        }
    }
    
    private var isValid: Bool {
        guard let limit = Double(limitDollars), limit > 0 else { return false }
        return periodEnd >= periodStart
    }
    
    private func saveBudget() {
        guard let limit = Double(limitDollars), limit > 0 else {
            errorMessage = "Please enter a valid amount"
            return
        }
        
        guard periodEnd >= periodStart else {
            errorMessage = "End date must be after start date"
            return
        }
        
        errorMessage = nil
        
        Task {
            await viewModel.updateBudget(
                budgetId: budget.id,
                periodStart: periodStart.toInputString(),
                periodEnd: periodEnd.toInputString(),
                category: category,
                limitCents: Int(limit * 100)
            )
            dismiss()
        }
    }
}

#Preview {
    CreateBudgetFormView(viewModel: BudgetsViewModel())
}

