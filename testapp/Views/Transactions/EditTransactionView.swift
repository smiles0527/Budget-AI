//
//  EditTransactionView.swift
//  testapp
//
//  Edit transaction form
//

import SwiftUI

struct EditTransactionView: View {
    @Environment(\.dismiss) var dismiss
    let transaction: Transaction
    @StateObject private var viewModel = TransactionsViewModel()
    
    @State private var merchant: String
    @State private var txnDate: Date
    @State private var totalDollars: String
    @State private var taxDollars: String
    @State private var tipDollars: String
    @State private var category: String
    @State private var subcategory: String
    @State private var errorMessage: String?
    
    let categories = ["groceries", "dining", "transport", "shopping", "entertainment", "subscriptions", "utilities", "health", "education", "travel", "other"]
    
    init(transaction: Transaction) {
        self.transaction = transaction
        _merchant = State(initialValue: transaction.merchant ?? "")
        _txnDate = State(initialValue: transaction.txn_date.toDate() ?? Date())
        _totalDollars = State(initialValue: String(format: "%.2f", Double(transaction.total_cents) / 100.0))
        _taxDollars = State(initialValue: transaction.tax_cents != nil ? String(format: "%.2f", Double(transaction.tax_cents!) / 100.0) : "")
        _tipDollars = State(initialValue: transaction.tip_cents != nil ? String(format: "%.2f", Double(transaction.tip_cents!) / 100.0) : "")
        _category = State(initialValue: transaction.category)
        _subcategory = State(initialValue: transaction.subcategory ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
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
                
                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat.capitalized).tag(cat)
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
            .navigationTitle("Edit Transaction")
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
                    .disabled(!isValid)
                }
            }
        }
    }
    
    private var isValid: Bool {
        guard let total = Double(totalDollars), total > 0 else { return false }
        return !merchant.isEmpty
    }
    
    private func saveTransaction() {
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
            await viewModel.updateTransaction(
                id: transaction.id,
                merchant: merchant,
                txnDate: txnDate.toInputString(),
                totalCents: Int(total * 100),
                taxCents: taxDollars.isEmpty ? nil : Int((Double(taxDollars) ?? 0) * 100),
                tipCents: tipDollars.isEmpty ? nil : Int((Double(tipDollars) ?? 0) * 100),
                category: category,
                subcategory: subcategory.isEmpty ? nil : subcategory
            )
            dismiss()
        }
    }
}

#Preview {
    EditTransactionView(transaction: Transaction(
        id: "1",
        user_id: "1",
        receipt_id: nil,
        merchant: "Test Merchant",
        txn_date: "2025-01-15",
        total_cents: 5000,
        tax_cents: 400,
        tip_cents: 1000,
        currency_code: "USD",
        category: "dining",
        subcategory: nil,
        source: "receipt",
        created_at: "2025-01-15T10:00:00Z",
        items: nil
    ))
}

