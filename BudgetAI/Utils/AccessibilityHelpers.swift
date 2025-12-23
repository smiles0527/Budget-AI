//
//  AccessibilityHelpers.swift
//  testapp
//
//  Accessibility helpers for VoiceOver and Dynamic Type support
//

import SwiftUI

// MARK: - Accessibility Labels

extension View {
    func accessibilityLabel(_ label: String) -> some View {
        self.accessibilityLabel(Text(label))
    }
    
    func accessibilityHint(_ hint: String) -> some View {
        self.accessibilityHint(Text(hint))
    }
}

// MARK: - Dynamic Type Support

struct DynamicTypeText: View {
    let text: String
    let style: Font.TextStyle
    
    init(_ text: String, style: Font.TextStyle = .body) {
        self.text = text
        self.style = style
    }
    
    var body: some View {
        Text(text)
            .font(.system(style))
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }
}

// MARK: - Accessibility Modifiers

extension View {
    func accessibleButton(label: String, hint: String? = nil) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(.isButton)
    }
    
    func accessibleHeader(label: String) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityAddTraits(.isHeader)
    }
    
    func accessibleValue(_ value: String) -> some View {
        self
            .accessibilityValue(value)
    }
}

// MARK: - Semantic Colors

struct AccessibleColor {
    static let primary = Color.primary
    static let secondary = Color.secondary
    static let accent = Color.accentColor
    static let success = Color.green
    static let warning = Color.orange
    static let error = Color.red
    
    // Ensure sufficient contrast for accessibility
    static func contrastColor(for background: Color) -> Color {
        // In a real implementation, you'd calculate contrast ratio
        // For now, return appropriate color based on background
        return .primary
    }
}






