//
//  SpendingTrendsChart.swift
//  testapp
//
//  Chart showing spending trends over time
//

import SwiftUI
import Charts

struct SpendingTrendsChart: View {
    let trends: SpendingTrendsResponse
    let viewModel: DashboardViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Spending Trends")
                .font(.headline)
            
            if trends.months.isEmpty {
                Text("No spending data available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            } else {
                Chart {
                    ForEach(sortedMonths, id: \.month) { monthData in
                        BarMark(
                            x: .value("Month", monthData.month),
                            y: .value("Spending", Double(monthData.data.total_cents) / 100.0)
                        )
                        .foregroundStyle(Color.blue.gradient)
                        .cornerRadius(4)
                    }
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .automatic) { value in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month(.abbreviated))
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let intValue = value.as(Double.self) {
                                Text(formatCurrency(intValue))
                            }
                        }
                    }
                }
                
                // Trend indicator
                HStack {
                    Image(systemName: trendIcon)
                        .foregroundColor(trendColor)
                    Text(trendText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private var sortedMonths: [(month: String, data: MonthData)] {
        trends.months.sorted { $0.key < $1.key }
            .map { (month: $0.key, data: $0.value) }
    }
    
    private var trendIcon: String {
        switch trends.trend {
        case "increasing":
            return "arrow.up.right"
        case "decreasing":
            return "arrow.down.right"
        default:
            return "arrow.right"
        }
    }
    
    private var trendColor: Color {
        switch trends.trend {
        case "increasing":
            return .red
        case "decreasing":
            return .green
        default:
            return .gray
        }
    }
    
    private var trendText: String {
        switch trends.trend {
        case "increasing":
            return "Spending is trending upward"
        case "decreasing":
            return "Spending is trending downward"
        default:
            return "Spending is stable"
        }
    }
    
    private func formatCurrency(_ dollars: Double) -> String {
        if dollars >= 1000 {
            return String(format: "$%.1fk", dollars / 1000.0)
        } else {
            return String(format: "$%.0f", dollars)
        }
    }
}

#Preview {
    SpendingTrendsChart(
        trends: SpendingTrendsResponse(
            months: [
                "2024-01": MonthData(total_cents: 50000, txn_count: 10, avg_txn_cents: 5000),
                "2024-02": MonthData(total_cents: 60000, txn_count: 12, avg_txn_cents: 5000),
                "2024-03": MonthData(total_cents: 55000, txn_count: 11, avg_txn_cents: 5000)
            ],
            trend: "increasing",
            period_months: 3
        ),
        viewModel: DashboardViewModel()
    )
}

