//
//  BadgeCelebrationView.swift
//  testapp
//
//  Badge celebration animation when user earns a badge
//

import SwiftUI

struct BadgeCelebrationView: View {
    let badge: Badge
    @Binding var isPresented: Bool
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var rotation: Double = 0
    @State private var showConfetti = false
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .opacity(opacity)
            
            // Confetti
            if showConfetti {
                ConfettiView()
            }
            
            // Badge Card
            VStack(spacing: 24) {
                // Badge Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.yellow, Color.orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .shadow(color: .yellow.opacity(0.5), radius: 20)
                    
                    Image(systemName: badgeIcon(for: badge.code))
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                }
                .scaleEffect(scale)
                .rotationEffect(.degrees(rotation))
                
                // Badge Name
                Text("Badge Earned!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .opacity(opacity)
                
                Text(badge.name)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.yellow)
                    .opacity(opacity)
                
                Text(badge.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .opacity(opacity)
                
                // Close Button
                Button(action: {
                    withAnimation(.easeOut(duration: 0.3)) {
                        opacity = 0
                        scale = 0.5
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isPresented = false
                    }
                }) {
                    Text("Awesome!")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(25)
                }
                .opacity(opacity)
            }
            .padding(32)
            .background(Color.white)
            .cornerRadius(24)
            .shadow(color: .black.opacity(0.3), radius: 20)
            .padding(40)
            .scaleEffect(scale)
        }
        .onAppear {
            // Animate in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                opacity = 1
                scale = 1.0
            }
            
            // Rotation animation
            withAnimation(.easeInOut(duration: 0.5).repeatCount(2, autoreverses: true)) {
                rotation = 360
            }
            
            // Show confetti after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showConfetti = true
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
}

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    
    var body: some View {
        GeometryReader { geometry in
            ForEach(particles, id: \.id) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
            }
        }
        .onAppear {
            createParticles()
        }
    }
    
    private func createParticles() {
        let colors: [Color] = [.yellow, .orange, .red, .pink, .purple, .blue]
        for i in 0..<50 {
            let particle = ConfettiParticle(
                id: i,
                position: CGPoint(
                    x: Double.random(in: 0...UIScreen.main.bounds.width),
                    y: -20
                ),
                color: colors.randomElement() ?? .yellow,
                size: CGFloat.random(in: 4...8)
            )
            particles.append(particle)
            
            // Animate particle falling
            withAnimation(.linear(duration: Double.random(in: 2...4)).delay(Double(i) * 0.05)) {
                if let index = particles.firstIndex(where: { $0.id == i }) {
                    particles[index].position.y = UIScreen.main.bounds.height + 100
                    particles[index].position.x += Double.random(in: -100...100)
                }
            }
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id: Int
    var position: CGPoint
    let color: Color
    let size: CGFloat
}

#Preview {
    BadgeCelebrationView(
        badge: Badge(code: "FIRST_SCAN", name: "First Scan", description: "Uploaded your first receipt"),
        isPresented: .constant(true)
    )
}

