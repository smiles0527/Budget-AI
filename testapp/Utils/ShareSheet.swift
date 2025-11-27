//
//  ShareSheet.swift
//  testapp
//
//  Utility for sharing content (badges, goals, streaks, etc.)
//

import SwiftUI
import UIKit

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    let excludedActivityTypes: [UIActivity.ActivityType]?
    
    init(items: [Any], excludedActivityTypes: [UIActivity.ActivityType]? = nil) {
        self.items = items
        self.excludedActivityTypes = excludedActivityTypes
    }
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        controller.excludedActivityTypes = excludedActivityTypes
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct ShareableBadgeImage: View {
    let badge: UserBadge
    @State private var image: UIImage?
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                ProgressView()
            }
        }
        .frame(width: 400, height: 400)
        .background(Color.white)
        .task {
            await generateImage()
        }
    }
    
    @available(iOS 16.0, *)
    private func generateImage() async {
        let renderer = ImageRenderer(content: BadgeShareView(badge: badge))
        renderer.scale = 2.0
        if let uiImage = renderer.uiImage {
            await MainActor.run {
                self.image = uiImage
            }
        }
    }
}

struct BadgeShareView: View {
    let badge: UserBadge
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: badgeIcon(for: badge.code))
                .font(.system(size: 100))
                .foregroundColor(.yellow)
            
            Text("Badge Earned!")
                .font(.system(size: 36, weight: .bold))
            
            Text(badge.name)
                .font(.system(size: 28, weight: .semibold))
            
            Text(badge.description)
                .font(.system(size: 18))
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 40)
            
            Text("SnapBudget")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.blue)
                .padding(.top, 20)
        }
        .frame(width: 400, height: 400)
        .background(
            LinearGradient(
                colors: [Color.yellow.opacity(0.2), Color.orange.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
    
    private func badgeIcon(for code: String) -> String {
        switch code {
        case "FIRST_SCAN": return "camera.fill"
        case "WEEK_STREAK_7": return "flame.fill"
        case "MONTH_STREAK_30": return "calendar.badge.clock"
        case "SAVINGS_GOAL_100", "SAVINGS_GOAL_500", "SAVINGS_GOAL_1000": return "banknote.fill"
        case "BUDGET_MASTER": return "chart.pie.fill"
        case "TRACKING_100", "TRACKING_500", "TRACKING_1000": return "list.bullet.rectangle.portrait.fill"
        default: return "star.fill"
        }
    }
}

struct ShareableGoalImage: View {
    let goal: SavingsGoal
    @State private var image: UIImage?
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                ProgressView()
            }
        }
        .frame(width: 400, height: 400)
        .background(Color.white)
        .task {
            await generateImage()
        }
    }
    
    @available(iOS 16.0, *)
    private func generateImage() async {
        let renderer = ImageRenderer(content: GoalShareView(goal: goal))
        renderer.scale = 2.0
        if let uiImage = renderer.uiImage {
            await MainActor.run {
                self.image = uiImage
            }
        }
    }
}

struct GoalShareView: View {
    let goal: SavingsGoal
    
    var progress: Double {
        guard goal.target_cents > 0 else { return 0 }
        let contributed = Double(goal.contributed_cents ?? 0)
        return min(1.0, contributed / Double(goal.target_cents))
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "target")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text("Savings Goal")
                .font(.system(size: 32, weight: .bold))
            
            Text(goal.name)
                .font(.system(size: 24, weight: .semibold))
                .multilineTextAlignment(.center)
            
            VStack(spacing: 12) {
                Text(CurrencyFormatter.shared.format(cents: goal.contributed_cents ?? 0))
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.green)
                
                Text("of \(CurrencyFormatter.shared.format(cents: goal.target_cents))")
                    .font(.system(size: 20))
                    .foregroundColor(.secondary)
                
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .green))
                    .frame(width: 200)
                    .scaleEffect(y: 2)
            }
            
            Text("SnapBudget")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.blue)
                .padding(.top, 20)
        }
        .frame(width: 400, height: 400)
        .background(
            LinearGradient(
                colors: [Color.green.opacity(0.2), Color.blue.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

struct ShareableStreakImage: View {
    let streakDays: Int
    @State private var image: UIImage?
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                ProgressView()
            }
        }
        .frame(width: 400, height: 400)
        .background(Color.white)
        .task {
            await generateImage()
        }
    }
    
    @available(iOS 16.0, *)
    private func generateImage() async {
        let renderer = ImageRenderer(content: StreakShareView(streakDays: streakDays))
        renderer.scale = 2.0
        if let uiImage = renderer.uiImage {
            await MainActor.run {
                self.image = uiImage
            }
        }
    }
}

struct StreakShareView: View {
    let streakDays: Int
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "flame.fill")
                .font(.system(size: 100))
                .foregroundColor(.orange)
            
            Text("\(streakDays)")
                .font(.system(size: 72, weight: .bold))
                .foregroundColor(.orange)
            
            Text("Day Streak!")
                .font(.system(size: 32, weight: .bold))
            
            Text("Keep tracking your spending!")
                .font(.system(size: 18))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Text("SnapBudget")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.blue)
                .padding(.top, 20)
        }
        .frame(width: 400, height: 400)
        .background(
            LinearGradient(
                colors: [Color.orange.opacity(0.2), Color.red.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

// Helper extension for sharing
extension View {
    func shareSheet(items: [Any], isPresented: Binding<Bool>) -> some View {
        self.sheet(isPresented: isPresented) {
            ShareSheet(items: items)
        }
    }
}

