//
//  TransactionListView.swift
//  testapp
//
//  Transaction list view
//

import SwiftUI

struct TransactionListView: View {
    @StateObject private var viewModel = TransactionsViewModel()
    @State private var searchText = ""
    @State private var showingFilters = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search transactions...", text: $searchText)
                        .onSubmit {
                            if !searchText.isEmpty {
                                Task {
                                    await viewModel.search(query: searchText)
                                }
                            } else {
                                Task {
                                    await viewModel.loadTransactions(refresh: true)
                                }
                            }
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            Task {
                                await viewModel.loadTransactions(refresh: true)
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
                
                // Transaction list
                if viewModel.isLoading && viewModel.transactions.isEmpty {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if viewModel.transactions.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "list.bullet")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("No transactions yet")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(viewModel.transactions, id: \.id) { transaction in
                            NavigationLink(destination: TransactionDetailView(transaction: transaction)) {
                                TransactionRow(transaction: transaction, viewModel: viewModel)
                            }
                        }
                        
                        if viewModel.hasMore {
                            Button("Load More") {
                                Task {
                                    await viewModel.loadMore()
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.blue)
                        }
                    }
                    .listStyle(PlainListStyle())
                    .refreshable {
                        await viewModel.loadTransactions(refresh: true)
                    }
                }
            }
            .navigationTitle("Transactions")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingFilters = true }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .sheet(isPresented: $showingFilters) {
                FilterView(viewModel: viewModel)
            }
            .task {
                await viewModel.loadTransactions(refresh: true)
            }
        }
    }
}

struct TransactionRow: View {
    let transaction: Transaction
    let viewModel: TransactionsViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            // Category icon
            Circle()
                .fill(colorForCategory(transaction.category))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(transaction.category.prefix(1)).uppercased())
                        .font(.headline)
                        .foregroundColor(.white)
                )
            
            // Transaction info
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.merchant ?? "Unknown Merchant")
                    .font(.headline)
                
                Text(transaction.category.capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(viewModel.formatDate(transaction.txn_date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Amount
            Text(viewModel.formatAmount(cents: transaction.total_cents))
                .font(.headline)
                .foregroundColor(.primary)
        }
        .padding(.vertical, 4)
    }
    
    private func colorForCategory(_ category: String) -> Color {
        switch category.lowercased() {
        case "groceries": return .green
        case "dining": return .orange
        case "transport": return .blue
        case "shopping": return .purple
        case "entertainment": return .pink
        case "subscriptions": return .red
        case "utilities": return .yellow
        case "health": return .red
        case "education": return .indigo
        case "travel": return .cyan
        default: return .gray
        }
    }
}

struct FilterView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: TransactionsViewModel
    @State private var fromDate = ""
    @State private var toDate = ""
    @State private var selectedCategory: String?
    
    let categories = ["groceries", "dining", "transport", "shopping", "entertainment", "subscriptions", "utilities", "health", "education", "travel", "other"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Date Range") {
                    TextField("From (YYYY-MM-DD)", text: $fromDate)
                    TextField("To (YYYY-MM-DD)", text: $toDate)
                }
                
                Section("Category") {
                    Picker("Category", selection: $selectedCategory) {
                        Text("All").tag(nil as String?)
                        ForEach(categories, id: \.self) { category in
                            Text(category.capitalized).tag(category as String?)
                        }
                    }
                }
                
                Section {
                    Button("Apply Filters") {
                        Task {
                            await viewModel.loadTransactions(
                                fromDate: fromDate.isEmpty ? nil : fromDate,
                                toDate: toDate.isEmpty ? nil : toDate,
                                category: selectedCategory,
                                refresh: true
                            )
                            dismiss()
                        }
                    }
                    
                    Button("Clear Filters") {
                        fromDate = ""
                        toDate = ""
                        selectedCategory = nil
                        Task {
                            await viewModel.loadTransactions(refresh: true)
                        }
                        dismiss()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct TransactionDetailView: View {
    let transaction: Transaction
    @StateObject private var viewModel = TransactionsViewModel()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(transaction.merchant ?? "Unknown Merchant")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(viewModel.formatAmount(cents: transaction.total_cents))
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .padding()
                
                // Details
                VStack(alignment: .leading, spacing: 12) {
                    DetailRow(label: "Date", value: viewModel.formatDate(transaction.txn_date))
                    DetailRow(label: "Category", value: transaction.category.capitalized)
                    if let subcategory = transaction.subcategory {
                        DetailRow(label: "Subcategory", value: subcategory)
                    }
                    DetailRow(label: "Total", value: viewModel.formatAmount(cents: transaction.total_cents))
                    if let tax = transaction.tax_cents, tax > 0 {
                        DetailRow(label: "Tax", value: viewModel.formatAmount(cents: tax))
                    }
                    if let tip = transaction.tip_cents, tip > 0 {
                        DetailRow(label: "Tip", value: viewModel.formatAmount(cents: tip))
                    }
                    DetailRow(label: "Source", value: transaction.source.capitalized)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Line items
                if let items = transaction.items, !items.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Line Items")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(items, id: \.id) { item in
                            HStack {
                                Text(item.description ?? "Item")
                                Spacer()
                                if let total = item.total_cents {
                                    Text(viewModel.formatAmount(cents: total))
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
        }
        .navigationTitle("Transaction")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    TransactionListView()
}

