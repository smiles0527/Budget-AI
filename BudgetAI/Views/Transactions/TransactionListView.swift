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
    @State private var selectedCategory: String?
    @State private var startDate: Date?
    @State private var endDate: Date?
    @State private var minAmount: Double?
    @State private var maxAmount: Double?
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.backgroundDark.ignoresSafeArea()
                
                VStack {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white.opacity(0.5))
                        .accessibilityHidden(true)
                    
                    TextField("Search transactions...", text: $searchText)
                        .textFieldStyle(.plain)
                        .foregroundColor(.white)
                        .accessibilityLabel("Search transactions")
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
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .accessibilityLabel("Clear search")
                    }
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
                .accessibilityElement(children: .combine)
                
                // Transaction list
                if viewModel.isLoading && viewModel.transactions.isEmpty {
                    List {
                        ForEach(0..<5, id: \.self) { _ in
                            TransactionRowSkeleton()
                        }
                        .listRowBackground(Color.white.opacity(0.05))
                    }
                    .listStyle(PlainListStyle())
                    .scrollContentBackground(.hidden)
                } else if viewModel.transactions.isEmpty {
                    EmptyStateView.noTransactions {
                        // Navigate to add transaction
                        // This would typically trigger a sheet or navigation
                    }
                } else {
                    List {
                        ForEach(viewModel.transactions, id: \.id) { transaction in
                            NavigationLink(destination: TransactionDetailView(transaction: transaction)) {
                                TransactionRow(transaction: transaction, viewModel: viewModel)
                            }
                            .listRowSeparator(.visible)
                            .listRowBackground(Color.white.opacity(0.05))
                        }
                        
                        if viewModel.hasMore {
                            Button("Load More") {
                                Task {
                                    await viewModel.loadMore()
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .foregroundColor(AppColors.primary)
                            .listRowBackground(Color.white.opacity(0.05))
                        }
                    }
                    .listStyle(PlainListStyle())
                    .scrollContentBackground(.hidden)
                    .refreshable {
                        await viewModel.loadTransactions(refresh: true)
                    }
                    .overlay(alignment: .top) {
                        if let error = viewModel.errorMessage {
                            ErrorBanner(
                                message: error,
                                retryAction: {
                                    Task {
                                        await viewModel.loadTransactions(refresh: true)
                                    }
                                },
                                dismissAction: {
                                    viewModel.errorMessage = nil
                                }
                            )
                            .padding()
                        }
                    }
                }
                }
            }
            .navigationTitle("Transactions")
            .toolbarBackground(AppColors.backgroundDark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingFilters = true }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .sheet(isPresented: $showingFilters) {
                TransactionFiltersView(
                    selectedCategory: $selectedCategory,
                    startDate: $startDate,
                    endDate: $endDate,
                    minAmount: $minAmount,
                    maxAmount: $maxAmount
                )
            }
            .onChange(of: selectedCategory) { _ in
                Task {
                    await applyFilters()
                }
            }
            .onChange(of: startDate) { _ in
                Task {
                    await applyFilters()
                }
            }
            .onChange(of: endDate) { _ in
                Task {
                    await applyFilters()
                }
            }
            .onChange(of: minAmount) { _ in
                Task {
                    await applyFilters()
                }
            }
            .onChange(of: maxAmount) { _ in
                Task {
                    await applyFilters()
                }
            }
            .task {
                await viewModel.loadTransactions(refresh: true)
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func applyFilters() async {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        
        await viewModel.loadTransactions(
            fromDate: startDate != nil ? formatter.string(from: startDate!) : nil,
            toDate: endDate != nil ? formatter.string(from: endDate!) : nil,
            category: selectedCategory,
            refresh: true
        )
        
        // Note: Amount filtering would need to be done client-side or added to backend
        // For now, we filter by category and date only
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
                .accessibilityLabel("Category: \(transaction.category)")
            
            // Transaction info
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.merchant ?? "Unknown Merchant")
                    .font(.headline)
                    .foregroundColor(.white)
                    .accessibilityLabel("Merchant: \(transaction.merchant ?? "Unknown Merchant")")
                
                Text(transaction.category.capitalized)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                
                Text(viewModel.formatDate(transaction.txn_date))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            // Amount
            Text(viewModel.formatAmount(cents: transaction.total_cents))
                .font(.headline)
                .foregroundColor(AppColors.accent)
                .accessibilityLabel("Amount: \(viewModel.formatAmount(cents: transaction.total_cents))")
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(transaction.merchant ?? "Unknown Merchant"), \(transaction.category), \(viewModel.formatAmount(cents: transaction.total_cents))")
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


#Preview {
    TransactionListView()
}

