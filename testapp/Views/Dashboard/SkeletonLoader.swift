//
//  SkeletonLoader.swift
//  testapp
//
//  Skeleton loading views for better perceived performance
//

import SwiftUI

struct SkeletonView: View {
    @State private var isAnimating = false
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.gray.opacity(0.2),
                        Color.gray.opacity(0.4),
                        Color.gray.opacity(0.2)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(8)
            .onAppear {
                withAnimation(
                    Animation.linear(duration: 1.5)
                        .repeatForever(autoreverses: false)
                ) {
                    isAnimating = true
                }
            }
    }
}

struct TransactionRowSkeleton: View {
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: 8) {
                SkeletonView()
                    .frame(width: 150, height: 16)
                SkeletonView()
                    .frame(width: 100, height: 12)
            }
            
            Spacer()
            
            SkeletonView()
                .frame(width: 80, height: 16)
        }
        .padding(.vertical, 8)
    }
}

struct BudgetRowSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SkeletonView()
                .frame(width: 120, height: 18)
            
            SkeletonView()
                .frame(height: 8)
                .cornerRadius(4)
            
            HStack {
                SkeletonView()
                    .frame(width: 100, height: 14)
                Spacer()
                SkeletonView()
                    .frame(width: 60, height: 14)
            }
        }
        .padding(.vertical, 8)
    }
}

struct CardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SkeletonView()
                .frame(width: 120, height: 20)
            
            SkeletonView()
                .frame(width: 200, height: 32)
            
            HStack {
                SkeletonView()
                    .frame(width: 100, height: 14)
                Spacer()
                SkeletonView()
                    .frame(width: 80, height: 14)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

#Preview {
    VStack(spacing: 20) {
        TransactionRowSkeleton()
        BudgetRowSkeleton()
        CardSkeleton()
    }
    .padding()
}





