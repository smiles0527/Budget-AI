//
//  AddExpenseView.swift
//  BudgetAI
//
//  "Log Spoils" / Gather Resources View
//

import SwiftUI

struct AddExpenseView: View {
    @State private var showingScanner = false
    @State private var showingManual = false
    @State private var isScanning = false
    @State private var animateScanner = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.backgroundDark.ignoresSafeArea()
                
                // Background Pattern (Grid)
                Image(systemName: "grid")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 600, height: 600)
                    .foregroundColor(AppColors.primary.opacity(0.05))
                    .rotationEffect(.degrees(30))
                
                VStack(spacing: 32) {
                    
                    // Header
                    VStack(spacing: 8) {
                        Text("Gather Resources")
                            .font(AppTypography.h2)
                            .foregroundColor(.white)
                            .shadow(color: AppColors.primary.opacity(0.5), radius: 10)
                        
                        Text("Scan magical artifacts (receipts)")
                            .font(AppTypography.body)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.top, 40)
                    
                    // Main Scanner Button (Camera Mockup)
                    Button(action: {
                        showingScanner = true
                    }) {
                        ZStack {
                            // Pulse Effect
                            Circle()
                                .fill(AppColors.primary.opacity(0.1))
                                .frame(width: 280, height: 280)
                                .scaleEffect(animateScanner ? 1.1 : 1.0)
                                .opacity(animateScanner ? 0.5 : 1.0)
                                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animateScanner)
                            
                            Circle()
                                .fill(AppColors.backgroundDark)
                                .frame(width: 240, height: 240)
                                .overlay(
                                    Circle()
                                        .stroke(AppColors.primary, lineWidth: 4)
                                )
                            
                            // Crosshair / Scanner UI
                            Image(systemName: "viewfinder")
                                .font(.system(size: 100, weight: .thin))
                                .foregroundColor(AppColors.primary)
                            
                            Image(systemName: "camera.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                            
                            // Scan line animation
                            Rectangle()
                                .fill(AppColors.primary)
                                .frame(width: 200, height: 2)
                                .offset(y: animateScanner ? 80 : -80)
                                .animation(.linear(duration: 2).repeatForever(autoreverses: true), value: animateScanner)
                                .mask(Circle().frame(width: 240, height: 240))
                        }
                    }
                    .padding()
                    
                    // Manual Entry Option
                    Button(action: {
                        showingManual = true
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "pencil.and.scribble")
                                .font(.headline)
                            Text("Scribe Manual Entry")
                                .font(AppTypography.bodyBold)
                        }
                        .foregroundColor(AppColors.accent)
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppColors.accent.opacity(0.3), lineWidth: 1)
                        )
                    }
                    
                    // Recent Scrolls
                    VStack(alignment: .leading, spacing: 16) {
                        Text("RECENT SCROLLS")
                            .font(AppTypography.small)
                            .foregroundColor(.white.opacity(0.6))
                            .tracking(1)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(0..<3) { _ in
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.05))
                                        .frame(width: 100, height: 140)
                                        .overlay(
                                            Image(systemName: "doc.text")
                                                .font(.largeTitle)
                                                .foregroundColor(.white.opacity(0.3))
                                        )
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    Spacer()
                }
            }
            .onAppear {
                animateScanner = true
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingScanner) {
                // Link to existing ReceiptCaptureView, wrapped in proper environment
                NavigationView {
                    ReceiptCaptureView()
                }
            }
            .sheet(isPresented: $showingManual) {
                ManualTransactionView()
            }
        }
    }
}

#Preview {
    AddExpenseView()
}
