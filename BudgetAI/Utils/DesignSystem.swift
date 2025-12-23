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
    static let primary = Color(hex: "#13ec6a") ?? .green // Neon Green
    static let primaryDark = Color(hex: "#0ea84c") ?? .green
    static let primaryLight = Color(hex: "#5cf498") ?? .green
    
    // Secondary Colors
    static let secondary = Color(hex: "#8b5cf6") ?? .purple // Quest Purple
    static let accent = Color(hex: "#fbbf24") ?? .yellow // Gold
    
    // Semantic Colors
    static let success = Color(hex: "#13ec6a") ?? .green
    static let warning = Color(hex: "#fbbf24") ?? .yellow
    static let error = Color(hex: "#ef4444") ?? .red
    static let info = Color(hex: "#3b82f6") ?? .blue
    
    // Neutral Colors
    static let background = Color(hex: "#f0f2f5") ?? Color(.systemGray6)
    static let backgroundDark = Color(hex: "#0b1215") ?? .black // Dark Stone
    
    static let surface = Color.white
    static let surfaceDark = Color(hex: "#1c1917") ?? .gray
    
    static let textPrimary = Color(hex: "#000000") ?? .primary
    static let textPrimaryDark = Color.white
    
    static let textSecondary = Color(hex: "#6b7280") ?? .secondary
    static let textSecondaryDark = Color(hex: "#9ca3af") ?? .gray
    
    // Rarity Colors
    static let rare = Color(hex: "#3b82f6") ?? .blue
    static let epic = Color(hex: "#a855f7") ?? .purple
    static let legendary = Color(hex: "#fbbf24") ?? .yellow
    
    // Gradients
    static let primaryGradient = LinearGradient(
        colors: [primary, primaryDark],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Typography
struct AppTypography {
    // Headings (Spline Sans proxy)
    static let h1 = Font.system(size: 32, weight: .black, design: .rounded)
    static let h2 = Font.system(size: 28, weight: .bold, design: .rounded)
    static let h3 = Font.system(size: 24, weight: .bold, design: .rounded)
    static let h4 = Font.system(size: 20, weight: .semibold, design: .rounded)
    
    // Body (Oxanium proxy)
    static let body = Font.system(size: 17, weight: .regular, design: .monospaced)
    static let bodyBold = Font.system(size: 17, weight: .bold, design: .monospaced)
    
    // Caption
    static let caption = Font.system(size: 14, weight: .medium, design: .rounded)
    static let captionBold = Font.system(size: 14, weight: .bold, design: .rounded)
    
    // Small
    static let small = Font.system(size: 12, weight: .medium, design: .monospaced)
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
    static let xxl: CGFloat = 32
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

