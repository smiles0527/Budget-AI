//
//  WelcomeView.swift
//  BudgetAI
//
//  Gamified landing page
//

import SwiftUI

struct WelcomeView: View {
    @Binding var showLogin: Bool
    @State private var animateFloat = false
    @State private var animateShine = false
    
    var body: some View {
        ZStack {
            // Background
            GeometryReader { geometry in
                RadialGradient(
                    colors: [AppColors.primaryDark.opacity(0.8), AppColors.backgroundDark],
                    center: .center,
                    startRadius: 0,
                    endRadius: geometry.size.height
                )
                .ignoresSafeArea()
            }
            
            // Rays Effect (Simulated with rotating gradient)
            AngularGradient(
                colors: [.white.opacity(0.03), .clear, .white.opacity(0.03), .clear],
                center: .center
            )
            .rotationEffect(.degrees(animateFloat ? 360 : 0))
            .animation(.linear(duration: 20).repeatForever(autoreverses: false), value: animateFloat)
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Title Section
                ZStack {
                    Text("SnapBudget")
                        .font(AppTypography.h1)
                        .foregroundColor(.white)
                        .shadow(color: .black, radius: 0, x: 0, y: 4)
                        .overlay(
                            Text("SnapBudget")
                                .font(AppTypography.h1)
                                .foregroundColor(.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 0)
                                        .stroke(Color.black, lineWidth: 1.5)
                                        .mask(Text("SnapBudget").font(AppTypography.h1))
                                )
                        )
                    
                    Image(systemName: "crown.fill")
                        .font(.system(size: 24))
                        .foregroundColor(AppColors.accent)
                        .offset(x: 80, y: -20)
                        .rotationEffect(.degrees(15))
                }
                .padding(.top, 40)
                
                // Hero Image / Animation Area
                ZStack {
                    // Floating Elements
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 250, height: 250)
                        .blur(radius: 30)
                    
                    // Coins
                    Image(systemName: "centsign.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(AppColors.accent)
                        .offset(x: 100, y: -80)
                        .offset(y: animateFloat ? -15 : 0)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateFloat)
                    
                    Image(systemName: "shield.fill")
                        .font(.system(size: 30))
                        .foregroundColor(AppColors.rare)
                        .offset(x: -100, y: 60)
                        .offset(y: animateFloat ? 15 : 0)
                        .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: animateFloat)
                    
                    // Main Graphic (Placeholder for the 3D phone)
                    RoundedRectangle(cornerRadius: 32)
                        .fill(Color.black.opacity(0.2))
                        .frame(width: 200, height: 350)
                        .overlay(
                            RoundedRectangle(cornerRadius: 32)
                                .stroke(Color.white.opacity(0.1), lineWidth: 4)
                        )
                        .overlay(
                            VStack {
                                Image(systemName: "wand.and.stars")
                                    .font(.system(size: 60))
                                    .foregroundColor(.white)
                                Text("Magic Tracking")
                                    .font(AppTypography.h3)
                                    .foregroundColor(.white)
                            }
                        )
                        .rotationEffect(.degrees(-5))
                        .offset(y: animateFloat ? -10 : 0)
                        .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: animateFloat)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 400)
                
                // Tagline
                VStack(spacing: 8) {
                    Text("Snap, Track, Save!")
                        .font(AppTypography.h2)
                        .foregroundColor(.white)
                    
                    Text("Turn receipts into gold.\nUse AI to defeat expenses and level up your budget!")
                        .font(AppTypography.body)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.bottom, 40)
                
                Spacer()
                
                // CTA Button
                Button(action: {
                    withAnimation {
                        showLogin = true
                    }
                }) {
                    ZStack {
                        // 3D Shadow
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(hex: "#d97706") ?? .orange) // Darker Gold
                            .offset(y: 6)
                        
                        // Main Button Surface
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AppColors.accent)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                        
                        // Shine Effect
                        HStack {
                            Rectangle()
                                .fill(Color.white.opacity(0.3))
                                .frame(width: 40)
                                .rotationEffect(.degrees(20))
                                .offset(x: animateShine ? 200 : -200)
                        }
                        .mask(RoundedRectangle(cornerRadius: 16))
                        
                        // Text
                        HStack {
                            Text("Start Your Quest")
                                .font(AppTypography.h3)
                                .foregroundColor(AppColors.textPrimary)
                                .textCase(.uppercase)
                            
                            Image(systemName: "arrow.right")
                                .font(.headline)
                                .foregroundColor(AppColors.textPrimary)
                        }
                    }
                    .frame(height: 64)
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 16)
                
                // Login Link
                Button(action: {
                    withAnimation {
                        showLogin = true
                    }
                }) {
                    Text("Already a player? Log In")
                        .font(AppTypography.bodyBold)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            animateFloat = true
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                animateShine = true
            }
        }
    }
}

#Preview {
    WelcomeView(showLogin: .constant(false))
}
