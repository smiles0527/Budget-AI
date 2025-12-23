//
//  TransactionFiltersView.swift
//  testapp
//
//  Visual filter interface for transactions
//

import SwiftUI

struct TransactionFiltersView: View {
    @Binding var selectedCategory: String?
    @Binding var startDate: Date?
    @Binding var endDate: Date?
    @Binding var minAmount: Double?
    @Binding var maxAmount: Double?
    
    @Environment(\.dismiss) var dismiss
    @State private var tempCategory: String?
    @State private var tempStartDate: Date?
    @State private var tempEndDate: Date?
    @State private var tempMinAmount: String = ""
    @State private var tempMaxAmount: String = ""
    
    let categories = ["groceries", "dining", "transport", "shopping", "entertainment", "subscriptions", "utilities", "health", "education", "travel", "other"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Category") {
                    Picker("Category", selection: $tempCategory) {
                        Text("All Categories").tag(nil as String?)
                        ForEach(categories, id: \.self) { category in
                            Text(category.capitalized).tag(category as String?)
                        }
                    }
                }
                
                Section("Date Range") {
                    Toggle("Filter by Date", isOn: Binding(
                        get: { tempStartDate != nil || tempEndDate != nil },
                        set: { enabled in
                            if !enabled {
                                tempStartDate = nil
                                tempEndDate = nil
                            } else if tempStartDate == nil && tempEndDate == nil {
                                let calendar = Calendar.current
                                let today = Date()
                                tempStartDate = calendar.date(byAdding: .month, value: -1, to: today) ?? today
                                tempEndDate = today
                            }
                        }
                    ))
                    
                    if tempStartDate != nil && tempEndDate != nil {
                        NavigationLink(destination: DateRangePickerView(
                            startDate: Binding(
                                get: { tempStartDate ?? Date() },
                                set: { tempStartDate = $0 }
                            ),
                            endDate: Binding(
                                get: { tempEndDate ?? Date() },
                                set: { tempEndDate = $0 }
                            )
                        )) {
                            HStack {
                                Text("Date Range")
                                Spacer()
                                Text("\(formatDate(tempStartDate ?? Date())) - \(formatDate(tempEndDate ?? Date()))")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                    }
                }
                
                Section("Amount Range") {
                    Toggle("Filter by Amount", isOn: Binding(
                        get: { !tempMinAmount.isEmpty || !tempMaxAmount.isEmpty },
                        set: { enabled in
                            if !enabled {
                                tempMinAmount = ""
                                tempMaxAmount = ""
                            }
                        }
                    ))
                    
                    if !tempMinAmount.isEmpty || !tempMaxAmount.isEmpty {
                        TextField("Min Amount ($)", text: $tempMinAmount)
                            .keyboardType(.decimalPad)
                        
                        TextField("Max Amount ($)", text: $tempMaxAmount)
                            .keyboardType(.decimalPad)
                    }
                }
                
                Section {
                    Button("Clear All Filters", role: .destructive) {
                        tempCategory = nil
                        tempStartDate = nil
                        tempEndDate = nil
                        tempMinAmount = ""
                        tempMaxAmount = ""
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        applyFilters()
                    }
                }
            }
        }
        .onAppear {
            // Initialize temp values from bindings
            tempCategory = selectedCategory
            tempStartDate = startDate
            tempEndDate = endDate
            tempMinAmount = minAmount != nil ? String(format: "%.2f", minAmount!) : ""
            tempMaxAmount = maxAmount != nil ? String(format: "%.2f", maxAmount!) : ""
        }
    }
    
    private func applyFilters() {
        selectedCategory = tempCategory
        startDate = tempStartDate
        endDate = tempEndDate
        minAmount = tempMinAmount.isEmpty ? nil : Double(tempMinAmount)
        maxAmount = tempMaxAmount.isEmpty ? nil : Double(tempMaxAmount)
        dismiss()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

