//
//  BadgeCollectionView.swift
//  testapp
//
//  Badge collection view showing all badges with earned/unearned states
//

import SwiftUI

struct BadgeCollectionView: View {
    @StateObject private var viewModel = BadgesViewModel()
    @State private var selectedBadge: Badge?
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 20) {
                ForEach(viewModel.allBadges, id: \.code) { badgeInfo in
                    BadgeGridItem(badgeInfo: badgeInfo)
                        .onTapGesture {
                            selectedBadge = badgeInfo.badge
                        }
                }
            }
            .padding()
        }
        .navigationTitle("Badges")
        .task {
            await viewModel.loadAllBadges()
        }
        .sheet(item: $selectedBadge) { badge in
            BadgeDetailView(badge: badge, isEarned: viewModel.isEarned(badgeCode: badge.code))
        }
    }
}

struct BadgeGridItem: View {
    let badgeInfo: BadgeInfo
    @StateObject private var viewModel = BadgesViewModel()
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(badgeInfo.isEarned ? Color.yellow.opacity(0.2) : Color.gray.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                if badgeInfo.isEarned {
                    Image(systemName: badgeIcon(for: badgeInfo.badge.code))
                        .font(.system(size: 40))
                        .foregroundColor(.yellow)
                } else {
                    Image(systemName: badgeIcon(for: badgeInfo.badge.code))
                        .font(.system(size: 40))
                        .foregroundColor(.gray.opacity(0.3))
                }
                
                if badgeInfo.isEarned {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.green)
                        .offset(x: 30, y: 30)
                } else {
                    // Progress indicator for unearned badges
                    if let progress = progressForBadge(badgeInfo.badge.code), progress > 0 {
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(Color.yellow, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .frame(width: 80, height: 80)
                    }
                }
            }
            
            Text(badgeInfo.badge.name)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .foregroundColor(badgeInfo.isEarned ? .primary : .secondary)
            
            // Progress text
            if !badgeInfo.isEarned, let progress = progressForBadge(badgeInfo.badge.code), progress > 0 {
                Text("\(Int(progress * 100))%")
                    .font(.caption2)
                    .foregroundColor(.yellow)
            }
        }
        .frame(height: 160)
    }
    
    private func progressForBadge(_ code: String) -> Double? {
        // This would need to be calculated based on user's current progress
        // For now, return nil to show no progress
        // In a real implementation, you'd check:
        // - For streak badges: current streak / required days
        // - For savings badges: current savings / required amount
        // - For tracking badges: transaction count / required count
        return nil
    }
    
    private func badgeIcon(for code: String) -> String {
        switch code {
        case "FIRST_SCAN": return "camera.fill"
        case "WEEK_STREAK_7": return "flame.fill"
        case "MONTH_STREAK_30": return "flame.fill"
        case "SAVINGS_GOAL_100", "SAVINGS_GOAL_500", "SAVINGS_GOAL_1000": return "dollarsign.circle.fill"
        case "BUDGET_MASTER": return "chart.pie.fill"
        case "TRACKING_100", "TRACKING_500", "TRACKING_1000": return "list.number"
        default: return "star.fill"
        }
    }
}

struct BadgeDetailView: View {
    let badge: Badge
    let isEarned: Bool
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Badge Icon
                    ZStack {
                        Circle()
                            .fill(isEarned ? Color.yellow.opacity(0.2) : Color.gray.opacity(0.1))
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: badgeIcon(for: badge.code))
                            .font(.system(size: 60))
                            .foregroundColor(isEarned ? .yellow : .gray.opacity(0.3))
                    }
                    .padding(.top, 40)
                    
                    // Badge Name
                    Text(badge.name)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    // Earned Status
                    if isEarned {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Earned")
                                .font(.headline)
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(20)
                    } else {
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.gray)
                            Text("Not Earned")
                                .font(.headline)
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(20)
                    }
                    
                    // Description
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Description")
                            .font(.headline)
                        
                        Text(badge.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(12)
                    
                    // How to Earn
                    VStack(alignment: .leading, spacing: 12) {
                        Text("How to Earn")
                            .font(.headline)
                        
                        Text(howToEarn(for: badge.code))
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Badge Details")
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
    
    private func badgeIcon(for code: String) -> String {
        switch code {
        case "FIRST_SCAN": return "camera.fill"
        case "WEEK_STREAK_7": return "flame.fill"
        case "MONTH_STREAK_30": return "flame.fill"
        case "SAVINGS_GOAL_100", "SAVINGS_GOAL_500", "SAVINGS_GOAL_1000": return "dollarsign.circle.fill"
        case "BUDGET_MASTER": return "chart.pie.fill"
        case "TRACKING_100", "TRACKING_500", "TRACKING_1000": return "list.number"
        default: return "star.fill"
        }
    }
    
    private func howToEarn(for code: String) -> String {
        switch code {
        case "FIRST_SCAN":
            return "Upload your first receipt to get started!"
        case "WEEK_STREAK_7":
            return "Track your spending for 7 consecutive days. Upload a receipt or add a transaction every day!"
        case "MONTH_STREAK_30":
            return "Track your spending for 30 consecutive days. Keep your streak going!"
        case "SAVINGS_GOAL_100":
            return "Reach a savings goal of $100 or more."
        case "SAVINGS_GOAL_500":
            return "Reach a savings goal of $500 or more."
        case "SAVINGS_GOAL_1000":
            return "Reach a savings goal of $1,000 or more."
        case "BUDGET_MASTER":
            return "Stay within all your budgets for an entire month."
        case "TRACKING_100":
            return "Track 100 transactions total."
        case "TRACKING_500":
            return "Track 500 transactions total."
        case "TRACKING_1000":
            return "Track 1,000 transactions total."
        default:
            return "Complete the required actions to earn this badge."
        }
    }
}

#Preview {
    NavigationView {
        BadgeCollectionView()
    }
}

