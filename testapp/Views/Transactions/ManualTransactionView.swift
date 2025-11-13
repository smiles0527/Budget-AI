//
//  ManualTransactionView.swift
//  testapp
//
//  Manual transaction entry form (premium feature)
//

import SwiftUI

struct ManualTransactionView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = TransactionsViewModel()
    @StateObject private var authManager = AuthManager.shared
    
    @State private var merchant = ""
    @State private var txnDate = Date()
    @State private var totalDollars = ""
    @State private var taxDollars = ""
    @State private var tipDollars = ""
    @State private var category: String? = nil
    @State private var subcategory = ""
    @State private var errorMessage: String?
    
    let categories = ["groceries", "dining", "transport", "shopping", "entertainment", "subscriptions", "utilities", "health", "education", "travel", "other"]
    
    var isPremium: Bool {
        authManager.subscription?.plan == "premium" && authManager.subscription?.status == "active"
    }
    
    var body: some View {
        NavigationView {
            Form {
                if !isPremium {
                    Section {
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.orange)
                            Text("Premium feature required")
                                .foregroundColor(.orange)
                        }
                        
                        NavigationLink("Upgrade to Premium") {
                            SubscriptionView()
                        }
                    }
                }
                
                Section("Transaction Details") {
                    TextField("Merchant", text: $merchant)
                    
                    DatePicker("Date", selection: $txnDate, displayedComponents: .date)
                    
                    TextField("Amount ($)", text: $totalDollars)
                        .keyboardType(.decimalPad)
                    
                    TextField("Tax ($)", text: $taxDollars)
                        .keyboardType(.decimalPad)
                    
                    TextField("Tip ($)", text: $tipDollars)
                        .keyboardType(.decimalPad)
                }
                
                Section("Category (Optional)") {
                    Picker("Category", selection: $category) {
                        Text("Auto-detect").tag(nil as String?)
                        ForEach(categories, id: \.self) { cat in
                            Text(cat.capitalized).tag(cat as String?)
                        }
                    }
                    
                    TextField("Subcategory (optional)", text: $subcategory)
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Add Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTransaction()
                    }
                    .disabled(!isValid || !isPremium)
                }
            }
        }
    }
    
    private var isValid: Bool {
        guard let total = Double(totalDollars), total > 0 else { return false }
        return !merchant.isEmpty
    }
    
    private func saveTransaction() {
        guard isPremium else {
            errorMessage = "Premium subscription required"
            return
        }
        
        guard let total = Double(totalDollars), total > 0 else {
            errorMessage = "Please enter a valid amount"
            return
        }
        
        guard !merchant.isEmpty else {
            errorMessage = "Please enter a merchant name"
            return
        }
        
        errorMessage = nil
        
        Task {
            await viewModel.createManualTransaction(
                merchant: merchant,
                txnDate: txnDate.toInputString(),
                totalCents: Int(total * 100),
                taxCents: taxDollars.isEmpty ? nil : Int((Double(taxDollars) ?? 0) * 100),
                tipCents: tipDollars.isEmpty ? nil : Int((Double(tipDollars) ?? 0) * 100),
                category: category,
                subcategory: subcategory.isEmpty ? nil : subcategory
            )
            
            if viewModel.errorMessage == nil {
                dismiss()
            } else {
                errorMessage = viewModel.errorMessage
            }
        }
    }
}

#Preview {
    ManualTransactionView()
}

