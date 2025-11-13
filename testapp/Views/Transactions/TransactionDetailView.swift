//
//  TransactionDetailView.swift
//  testapp
//
//  Transaction detail view with items and edit/delete
//

import SwiftUI

struct TransactionDetailView: View {
    let transaction: Transaction
    @StateObject private var viewModel = TransactionDetailViewModel()
    @StateObject private var tagsViewModel = TagsViewModel()
    @State private var showingEdit = false
    @State private var showingDeleteAlert = false
    @State private var showingTagPicker = false
    @State private var transactionTags: [Tag] = []
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        List {
            Section("Transaction Details") {
                HStack {
                    Text("Merchant")
                    Spacer()
                    Text(transaction.merchant ?? "Unknown")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Date")
                    Spacer()
                    Text(transaction.txn_date.toDisplayDate())
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Amount")
                    Spacer()
                    Text(CurrencyFormatter.shared.format(cents: transaction.total_cents))
                        .foregroundColor(.primary)
                        .fontWeight(.semibold)
                }
                
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
                
                if let tax = transaction.tax_cents, tax > 0 {
                    HStack {
                        Text("Tax")
                        Spacer()
                        Text(CurrencyFormatter.shared.format(cents: tax))
                            .foregroundColor(.secondary)
                    }
                }
                
                if let tip = transaction.tip_cents, tip > 0 {
                    HStack {
                        Text("Tip")
                        Spacer()
                        Text(CurrencyFormatter.shared.format(cents: tip))
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    Text("Source")
                    Spacer()
                    Text(transaction.source.capitalized)
                        .foregroundColor(.secondary)
                }
            }
            
            if let items = viewModel.items, !items.isEmpty {
                Section("Line Items") {
                    ForEach(items, id: \.id) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            if let description = item.description {
                                Text(description)
                                    .font(.body)
                            }
                            
                            HStack {
                                if let quantity = item.quantity {
                                    Text("Qty: \(quantity, specifier: "%.2f")")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                if let unitPrice = item.unit_price_cents {
                                    Text("@ \(CurrencyFormatter.shared.format(cents: unitPrice))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if let total = item.total_cents {
                                    Text(CurrencyFormatter.shared.format(cents: total))
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                            }
                            
                            if let category = item.category {
                                Text(category.capitalized)
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            
            Section("Tags") {
                if transactionTags.isEmpty {
                    Text("No tags")
                        .foregroundColor(.secondary)
                        .font(.caption)
                } else {
                    ForEach(transactionTags, id: \.id) { tag in
                        HStack {
                            if let color = tag.color {
                                Circle()
                                    .fill(Color(hex: color) ?? .blue)
                                    .frame(width: 12, height: 12)
                            }
                            Text(tag.name)
                            Spacer()
                            Button(action: {
                                Task {
                                    await viewModel.removeTag(transactionId: transaction.id, tagId: tag.id)
                                    await loadTags()
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                    }
                }
                
                Button(action: { showingTagPicker = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Tag")
                    }
                    .foregroundColor(.blue)
                }
            }
            
            Section {
                Button(action: { showingEdit = true }) {
                    HStack {
                        Image(systemName: "pencil")
                        Text("Edit Transaction")
                    }
                    .foregroundColor(.blue)
                }
                
                Button(action: { showingDeleteAlert = true }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Delete Transaction")
                    }
                    .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("Transaction")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEdit) {
            EditTransactionView(transaction: transaction)
        }
        .alert("Delete Transaction", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteTransaction(id: transaction.id)
                    dismiss()
                }
            }
        } message: {
            Text("Are you sure you want to delete this transaction? This action cannot be undone.")
        }
        .sheet(isPresented: $showingTagPicker) {
            TagPickerView(
                transactionId: transaction.id,
                currentTags: transactionTags,
                onTagAdded: {
                    Task {
                        await loadTags()
                    }
                }
            )
        }
        .task {
            await viewModel.loadItems(transactionId: transaction.id)
            await loadTags()
        }
    }
    
    private func loadTags() async {
        await tagsViewModel.loadTags()
        // Filter tags that are assigned to this transaction
        // Note: In a real implementation, you'd fetch transaction tags from the API
        // For now, we'll show all tags and let the user add/remove
        transactionTags = []
    }
}

@MainActor
class TransactionDetailViewModel: ObservableObject {
    @Published var items: [TransactionItem]?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiClient = APIClient.shared
    
    func loadItems(transactionId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiClient.getTransactionItems(id: transactionId)
            items = response.items
        } catch {
            errorMessage = ErrorHandler.userFriendlyMessage(for: error)
        }
        
        isLoading = false
    }
    
    func deleteTransaction(id: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await apiClient.deleteTransaction(id: id)
        } catch {
            errorMessage = ErrorHandler.userFriendlyMessage(for: error)
        }
        
        isLoading = false
    }
    
    func addTag(transactionId: String, tagId: String) async {
        do {
            try await apiClient.addTagToTransaction(transactionId: transactionId, tagId: tagId)
        } catch {
            errorMessage = ErrorHandler.userFriendlyMessage(for: error)
        }
    }
    
    func removeTag(transactionId: String, tagId: String) async {
        do {
            try await apiClient.removeTagFromTransaction(transactionId: transactionId, tagId: tagId)
        } catch {
            errorMessage = ErrorHandler.userFriendlyMessage(for: error)
        }
    }
}

#Preview {
    NavigationView {
        TransactionDetailView(transaction: Transaction(
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
}

