//
//  CategoryBreakdownChart.swift
//  testapp
//
//  Pie chart showing spending by category
//

import SwiftUI
import Charts

struct CategoryBreakdownChart: View {
    let categories: [CategorySpending]
    let viewModel: DashboardViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Category Breakdown")
                .font(.headline)
            
            if categories.isEmpty {
                Text("No spending data available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            } else {
                HStack(spacing: 20) {
                    // Pie Chart
                    Chart {
                        ForEach(categories.prefix(8), id: \.category) { category in
                            SectorMark(
                                angle: .value("Spending", Double(category.total_spend_cents)),
                                innerRadius: .ratio(0.5),
                                angularInset: 2
                            )
                            .foregroundStyle(colorForCategory(category.category))
                            .annotation(position: .overlay) {
                                if categoryPercentage(category) > 10 {
                                    Text(String(format: "%.0f%%", categoryPercentage(category)))
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                }
                            }
                        }
                    }
                    .frame(height: 200)
                    
                    // Legend
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(categories.prefix(6), id: \.category) { category in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(colorForCategory(category.category))
                                    .frame(width: 12, height: 12)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(category.category.capitalized)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                    Text(viewModel.formatAmount(cents: category.total_spend_cents))
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        
                        if categories.count > 6 {
                            Text("+ \(categories.count - 6) more")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private func categoryPercentage(_ category: CategorySpending) -> Double {
        let total = categories.reduce(0) { $0 + $1.total_spend_cents }
        guard total > 0 else { return 0 }
        return (Double(category.total_spend_cents) / Double(total)) * 100.0
    }
    
    private func colorForCategory(_ category: String) -> Color {
        let colors: [String: Color] = [
            "groceries": .green,
            "dining": .orange,
            "transport": .blue,
            "shopping": .purple,
            "entertainment": .pink,
            "subscriptions": .red,
            "utilities": .yellow,
            "health": .cyan,
            "education": .indigo,
            "travel": .mint,
            "other": .gray
        ]
        return colors[category.lowercased()] ?? .blue
    }
}

#Preview {
    CategoryBreakdownChart(
        categories: [
            CategorySpending(category: "groceries", total_spend_cents: 50000, txn_count: 20),
            CategorySpending(category: "dining", total_spend_cents: 30000, txn_count: 15),
            CategorySpending(category: "transport", total_spend_cents: 20000, txn_count: 10)
        ],
        viewModel: DashboardViewModel()
    )
}

