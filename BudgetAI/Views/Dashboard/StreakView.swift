//
//  StreakView.swift
//  testapp
//
//  Streak display component for dashboard
//

import SwiftUI

struct StreakView: View {
    @StateObject private var viewModel = StreakViewModel()
    @State private var showingShareSheet = false
    @State private var shareItems: [Any] = []
    
    var body: some View {
        HStack(spacing: 16) {
            // Flame Icon
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: "flame.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.orange)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(viewModel.currentStreak)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.orange)
                
                Text(viewModel.streakText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Next badge indicator with progress
            if let nextBadge = viewModel.nextStreakBadge {
                VStack(alignment: .trailing, spacing: 8) {
                    Text("Next Badge")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 4)
                                .cornerRadius(2)
                            
                            Rectangle()
                                .fill(Color.yellow)
                                .frame(
                                    width: geometry.size.width * viewModel.progressToNextBadge,
                                    height: 4
                                )
                                .cornerRadius(2)
                        }
                    }
                    .frame(width: 80, height: 4)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                        Text("\(viewModel.daysUntilNextBadge) days")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.orange.opacity(0.1), Color.red.opacity(0.05)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(12)
        .contextMenu {
            if viewModel.currentStreak > 0 {
                Button(action: {
                    shareStreak()
                }) {
                    Label("Share Streak", systemImage: "square.and.arrow.up")
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: shareItems)
        }
        .task {
            await viewModel.loadStreak()
        }
    }
    
    private func shareStreak() {
        let text = "🔥 \(viewModel.currentStreak) day streak on SnapBudget! Keep tracking your spending! #SnapBudget"
        shareItems = [text]
        showingShareSheet = true
    }
}

@MainActor
class StreakViewModel: ObservableObject {
    @Published var currentStreak: Int = 0
    @Published var transactionDates: [Date] = []
    
    private let apiClient = APIClient.shared
    
    var streakText: String {
        if currentStreak == 0 {
            return "Start your streak!"
        } else if currentStreak == 1 {
            return "day streak"
        } else {
            return "day streak"
        }
    }
    
    var nextStreakBadge: String? {
        if currentStreak < 7 {
            return "WEEK_STREAK_7"
        } else if currentStreak < 30 {
            return "MONTH_STREAK_30"
        }
        return nil
    }
    
    var daysUntilNextBadge: Int {
        if let next = nextStreakBadge {
            if next == "WEEK_STREAK_7" {
                return max(0, 7 - currentStreak)
            } else if next == "MONTH_STREAK_30" {
                return max(0, 30 - currentStreak)
            }
        }
        return 0
    }
    
    var progressToNextBadge: Double {
        if let next = nextStreakBadge {
            if next == "WEEK_STREAK_7" {
                return min(1.0, Double(currentStreak) / 7.0)
            } else if next == "MONTH_STREAK_30" {
                return min(1.0, Double(currentStreak) / 30.0)
            }
        }
        return 0
    }
    
    func loadStreak() async {
        // Get transactions from last 30 days to calculate streak
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -30, to: endDate) ?? endDate
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        
        do {
            let response = try await apiClient.getTransactions(
                fromDate: formatter.string(from: startDate),
                toDate: formatter.string(from: endDate),
                limit: 1000
            )
            
            // Extract unique dates
            let dates = response.items.compactMap { transaction -> Date? in
                let dateFormatter = ISO8601DateFormatter()
                dateFormatter.formatOptions = [.withFullDate, .withTime]
                return dateFormatter.date(from: transaction.txn_date)
            }
            
            // Get unique dates only
            let uniqueDates = Array(Set(dates.map { calendar.startOfDay(for: $0) })).sorted(by: >)
            transactionDates = uniqueDates
            
            // Calculate current streak
            currentStreak = calculateStreak(from: uniqueDates)
        } catch {
            print("Error loading streak: \(error)")
        }
    }
    
    private func calculateStreak(from dates: [Date]) -> Int {
        guard !dates.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var streak = 0
        var currentDate = today
        
        // Check if there's a transaction today
        if dates.contains(where: { calendar.isDate($0, inSameDayAs: today) }) {
            streak = 1
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
        } else {
            // If no transaction today, check yesterday
            let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today
            if dates.contains(where: { calendar.isDate($0, inSameDayAs: yesterday) }) {
                streak = 1
                currentDate = yesterday
            } else {
                return 0
            }
        }
        
        // Count consecutive days going backwards
        while true {
            if dates.contains(where: { calendar.isDate($0, inSameDayAs: currentDate) }) {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else {
                break
            }
        }
        
        return streak
    }
}

#Preview {
    StreakView()
        .padding()
}

