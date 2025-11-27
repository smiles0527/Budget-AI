//
//  DashboardView.swift
//  testapp
//
//  Dashboard with spending overview
//

import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @State private var selectedPeriod = "month"
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Usage Limit (for free users)
                    UsageLimitView()
                    
                    // Streak View
                    StreakView()
                    
                    // Summary card
                    if viewModel.isLoading && viewModel.summary == nil {
                        CardSkeleton()
                    } else if let summary = viewModel.summary {
                        SummaryCard(summary: summary, viewModel: viewModel)
                    }
                    
                    // Spending Trends Chart
                    if let trends = viewModel.spendingTrends {
                        SpendingTrendsChart(trends: trends, viewModel: viewModel)
                    }
                    
                    // Category breakdown chart
                    if !viewModel.categories.isEmpty {
                        CategoryBreakdownChart(categories: viewModel.categories, viewModel: viewModel)
                    }
                    
                    // Category breakdown list (alternative view)
                    if !viewModel.categories.isEmpty {
                        CategoryBreakdownView(categories: viewModel.categories, viewModel: viewModel)
                    }
                    
                    // Insights
                    if !viewModel.insights.isEmpty {
                        InsightsView(insights: viewModel.insights)
                    }
                    
                    // Forecast
                    if let forecast = viewModel.forecast {
                        ForecastCard(forecast: forecast, viewModel: viewModel)
                    }
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Picker("Period", selection: $selectedPeriod) {
                        Text("Month").tag("month")
                        Text("Week").tag("week")
                        Text("Year").tag("year")
                    }
                    .pickerStyle(.menu)
                }
            }
            .task {
                await viewModel.loadDashboard(period: selectedPeriod)
                await viewModel.loadTrends(months: 6)
                await viewModel.loadInsights()
                await viewModel.loadForecast()
            }
            .onChange(of: selectedPeriod) { newValue in
                Task {
                    await viewModel.loadDashboard(period: newValue)
                }
            }
        }
    }
}

struct SummaryCard: View {
    let summary: DashboardSummary
    let viewModel: DashboardViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Spending Summary")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.formatAmount(cents: summary.total_spend_cents))
                    .font(.system(size: 36, weight: .bold))
                    .accessibilityLabel("Total spending: \(viewModel.formatAmount(cents: summary.total_spend_cents))")
                
                HStack {
                    Text("\(summary.txn_count) transactions")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .accessibilityLabel("\(summary.txn_count) transactions")
                    
                    Spacer()
                    
                    Text("Avg: \(viewModel.formatAmount(cents: Int(summary.avg_txn_cents)))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .accessibilityLabel("Average transaction: \(viewModel.formatAmount(cents: Int(summary.avg_txn_cents)))")
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
    }
}

struct CategoryBreakdownView: View {
    let categories: [CategorySpending]
    let viewModel: DashboardViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Category Breakdown")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            
            let total = categories.reduce(0) { $0 + $1.total_spend_cents }
            
            ForEach(categories.prefix(5), id: \.category) { category in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(category.category.capitalized)
                            .font(.subheadline)
                            .accessibilityLabel("Category: \(category.category)")
                        Spacer()
                        Text(viewModel.formatAmount(cents: category.total_spend_cents))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .accessibilityLabel("Amount: \(viewModel.formatAmount(cents: category.total_spend_cents))")
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 8)
                                .cornerRadius(4)
                            
                            Rectangle()
                                .fill(Color.blue)
                                .frame(
                                    width: geometry.size.width * CGFloat(viewModel.categoryPercentage(
                                        cents: category.total_spend_cents,
                                        total: total
                                    ) / 100.0),
                                    height: 8
                                )
                                .cornerRadius(4)
                        }
                    }
                    .frame(height: 8)
                    .accessibilityValue("\(Int(viewModel.categoryPercentage(cents: category.total_spend_cents, total: total)))%")
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

struct InsightsView: View {
    let insights: [Insight]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Insights")
                .font(.headline)
            
            ForEach(insights.prefix(3), id: \.message) { insight in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: iconForSeverity(insight.severity))
                        .foregroundColor(colorForSeverity(insight.severity))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(insight.message)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(insight.recommendation)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    private func iconForSeverity(_ severity: String) -> String {
        switch severity {
        case "critical": return "exclamationmark.triangle.fill"
        case "warning": return "exclamationmark.circle.fill"
        case "positive": return "checkmark.circle.fill"
        default: return "info.circle.fill"
        }
    }
    
    private func colorForSeverity(_ severity: String) -> Color {
        switch severity {
        case "critical": return .red
        case "warning": return .orange
        case "positive": return .green
        default: return .blue
        }
    }
}

struct ForecastCard: View {
    let forecast: SpendingForecastResponse
    let viewModel: DashboardViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Spending Forecast")
                .font(.headline)
            
            Text("Next \(forecast.months_ahead) month(s): \(viewModel.formatAmount(cents: forecast.forecast_cents))")
                .font(.subheadline)
            
            Text("Per month: \(viewModel.formatAmount(cents: forecast.forecast_per_month_cents))")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Text("Confidence: \(forecast.confidence.capitalized)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Based on \(forecast.based_on_months) months")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    DashboardView()
}

