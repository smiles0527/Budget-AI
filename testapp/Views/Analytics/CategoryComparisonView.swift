//
//  CategoryComparisonView.swift
//  testapp
//
//  Category comparison analytics view
//

import SwiftUI

struct CategoryComparisonView: View {
    @StateObject private var viewModel = CategoryComparisonViewModel()
    @State private var period1Start = Calendar.current.date(byAdding: .month, value: -2, to: Date()) ?? Date()
    @State private var period1End = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var period2Start = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var period2End = Date()
    @State private var showingDatePicker = false
    @State private var selectedPeriod = 0
    
    var body: some View {
        List {
            Section("Period 1") {
                HStack {
                    Text("Start")
                    Spacer()
                    Text(period1Start.toDisplayString())
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("End")
                    Spacer()
                    Text(period1End.toDisplayString())
                        .foregroundColor(.secondary)
                }
            }
            
            Section("Period 2") {
                HStack {
                    Text("Start")
                    Spacer()
                    Text(period2Start.toDisplayString())
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("End")
                    Spacer()
                    Text(period2End.toDisplayString())
                        .foregroundColor(.secondary)
                }
            }
            
            Section {
                Button("Compare Periods") {
                    Task {
                        await viewModel.comparePeriods(
                            period1Start: period1Start.toInputString(),
                            period1End: period1End.toInputString(),
                            period2Start: period2Start.toInputString(),
                            period2End: period2End.toInputString()
                        )
                    }
                }
                .disabled(viewModel.isLoading)
            }
            
            if viewModel.isLoading {
                Section {
                    ProgressView()
                }
            }
            
            if !viewModel.comparison.isEmpty {
                Section("Comparison Results") {
                    ForEach(viewModel.comparison, id: \.category) { item in
                        CategoryComparisonRow(item: item)
                    }
                }
            }
            
            if let error = viewModel.errorMessage {
                Section {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
        }
        .navigationTitle("Category Comparison")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingDatePicker) {
            // Date picker would go here
        }
    }
}

struct CategoryComparisonRow: View {
    let item: CategoryComparisonItem
    
    var changeColor: Color {
        if item.change_cents > 0 {
            return .red
        } else if item.change_cents < 0 {
            return .green
        } else {
            return .secondary
        }
    }
    
    var changeIcon: String {
        if item.change_cents > 0 {
            return "arrow.up.right"
        } else if item.change_cents < 0 {
            return "arrow.down.right"
        } else {
            return "minus"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(item.category.capitalized)
                    .font(.headline)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: changeIcon)
                        .foregroundColor(changeColor)
                        .font(.caption)
                    Text(CurrencyFormatter.shared.format(cents: abs(item.change_cents)))
                        .foregroundColor(changeColor)
                        .fontWeight(.medium)
                }
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Period 1")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(CurrencyFormatter.shared.format(cents: item.period1_total_cents))
                        .font(.subheadline)
                    Text("\(item.period1_txn_count) transactions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Period 2")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(CurrencyFormatter.shared.format(cents: item.period2_total_cents))
                        .font(.subheadline)
                    Text("\(item.period2_txn_count) transactions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if let percent = item.change_percent {
                HStack {
                    Text("Change: \(String(format: "%.1f", percent))%")
                        .font(.caption)
                        .foregroundColor(changeColor)
                    Spacer()
                }
            }
        }
        .padding(.vertical, 4)
    }
}

@MainActor
class CategoryComparisonViewModel: ObservableObject {
    @Published var comparison: [CategoryComparisonItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiClient = APIClient.shared
    
    func comparePeriods(
        period1Start: String,
        period1End: String,
        period2Start: String,
        period2End: String
    ) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiClient.getCategoryComparison(
                period1Start: period1Start,
                period1End: period1End,
                period2Start: period2Start,
                period2End: period2End
            )
            comparison = response.comparison
        } catch {
            errorMessage = ErrorHandler.userFriendlyMessage(for: error)
        }
        
        isLoading = false
    }
}

#Preview {
    NavigationView {
        CategoryComparisonView()
    }
}

