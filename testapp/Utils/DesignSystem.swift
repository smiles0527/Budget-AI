//
//  DesignSystem.swift
//  testapp
//
//  Design system synced from Figma
//  Run sync script to update from Figma: ./scripts/sync-figma-tokens.sh
//

import SwiftUI

// MARK: - Colors
struct AppColors {
    // Primary Colors
    static let primary = Color(hex: "#007AFF") ?? .blue
    static let primaryDark = Color(hex: "#0051D5") ?? .blue
    static let primaryLight = Color(hex: "#5AC8FA") ?? .blue
    
    // Secondary Colors
    static let secondary = Color(hex: "#5856D6") ?? .purple
    static let accent = Color(hex: "#FF9500") ?? .orange
    
    // Semantic Colors
    static let success = Color(hex: "#34C759") ?? .green
    static let warning = Color(hex: "#FF9500") ?? .orange
    static let error = Color(hex: "#FF3B30") ?? .red
    static let info = Color(hex: "#007AFF") ?? .blue
    
    // Neutral Colors
    static let background = Color(hex: "#F2F2F7") ?? Color(.systemGray6)
    static let surface = Color.white
    static let textPrimary = Color(hex: "#000000") ?? .primary
    static let textSecondary = Color(hex: "#8E8E93") ?? .secondary
    
    // Badge Colors
    static let badgeGold = Color(hex: "#FFD700") ?? .yellow
    static let badgeSilver = Color(hex: "#C0C0C0") ?? .gray
    static let badgeBronze = Color(hex: "#CD7F32") ?? .orange
    
    // Premium Colors
    static let premiumGold = Color(hex: "#FFD700") ?? .yellow
    static let premiumGradient = LinearGradient(
        colors: [Color(hex: "#FFD700") ?? .yellow, Color(hex: "#FFA500") ?? .orange],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Typography
struct AppTypography {
    // Headings
    static let h1 = Font.system(size: 32, weight: .bold, design: .default)
    static let h2 = Font.system(size: 28, weight: .bold, design: .default)
    static let h3 = Font.system(size: 24, weight: .semibold, design: .default)
    static let h4 = Font.system(size: 20, weight: .semibold, design: .default)
    
    // Body
    static let body = Font.system(size: 17, weight: .regular, design: .default)
    static let bodyBold = Font.system(size: 17, weight: .semibold, design: .default)
    
    // Caption
    static let caption = Font.system(size: 15, weight: .regular, design: .default)
    static let captionBold = Font.system(size: 15, weight: .semibold, design: .default)
    
    // Small
    static let small = Font.system(size: 13, weight: .regular, design: .default)
    static let smallBold = Font.system(size: 13, weight: .semibold, design: .default)
}

// MARK: - Spacing
struct AppSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Corner Radius
struct AppCornerRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let xlarge: CGFloat = 24
}

// MARK: - Shadows
struct AppShadows {
    static let small = Shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    static let medium = Shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    static let large = Shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
}

struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Design System Sync Helper
class DesignSystemSync {
    static func syncFromFigma() async {
        do {
            let tokens = try await FigmaService.shared.fetchDesignTokens()
            // Update design system with tokens from Figma
            // This would typically write to a file or update UserDefaults
            print("Synced \(tokens.colors.count) colors, \(tokens.typography.count) typography styles, \(tokens.spacing.count) spacing values")
        } catch {
            print("Error syncing from Figma: \(error)")
        }
    }
}

