//
//  CategoryOverrideView.swift
//  testapp
//
//  Quick category override view for fixing incorrect categories
//

import SwiftUI

struct CategoryOverrideView: View {
    let transaction: Transaction
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = TransactionsViewModel()
    @State private var selectedCategory: String
    @State private var selectedSubcategory: String = ""
    @State private var errorMessage: String?
    
    let categories = ["groceries", "dining", "transport", "shopping", "entertainment", "subscriptions", "utilities", "health", "education", "travel", "other"]
    
    init(transaction: Transaction) {
        self.transaction = transaction
        _selectedCategory = State(initialValue: transaction.category)
        _selectedSubcategory = State(initialValue: transaction.subcategory ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Current Category") {
                    HStack {
                        Text("Category")
                        Spacer()
                        Text(transaction.category.capitalized)
                            .foregroundColor(.secondary)
                    }
                    
                    if let subcategory = transaction.subcategory {
                        HStack {
                            Text("Subcategory")
                            Spacer()
                            Text(subcategory)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("New Category") {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { category in
                            Text(category.capitalized).tag(category)
                        }
                    }
                    
                    TextField("Subcategory (optional)", text: $selectedSubcategory)
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Fix Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveCategory()
                    }
                    .disabled(selectedCategory == transaction.category && selectedSubcategory == (transaction.subcategory ?? ""))
                }
            }
        }
    }
    
    private func saveCategory() {
        errorMessage = nil
        
        Task {
            await viewModel.updateTransaction(
                id: transaction.id,
                merchant: transaction.merchant ?? "",
                txnDate: transaction.txn_date,
                totalCents: transaction.total_cents,
                taxCents: transaction.tax_cents,
                tipCents: transaction.tip_cents,
                category: selectedCategory,
                subcategory: selectedSubcategory.isEmpty ? nil : selectedSubcategory
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
    CategoryOverrideView(transaction: Transaction(
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





