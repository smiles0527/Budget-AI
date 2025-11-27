//
//  EmptyStateView.swift
//  testapp
//
//  Reusable empty state component
//

import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.6))
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 60)
    }
}

// Predefined empty states
extension EmptyStateView {
    static func noTransactions(action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "list.bullet",
            title: "No Transactions Yet",
            message: "Start tracking your spending by uploading a receipt or adding a manual transaction.",
            actionTitle: "Add Transaction",
            action: action
        )
    }
    
    static func noBudgets(action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "chart.pie",
            title: "No Budgets Set",
            message: "Create a budget to track your spending and stay on target.",
            actionTitle: "Create Budget",
            action: action
        )
    }
    
    static func noSavingsGoals(action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "target",
            title: "No Savings Goals",
            message: "Set a savings goal to track your progress and stay motivated.",
            actionTitle: "Create Goal",
            action: action
        )
    }
    
    static func noReceipts() -> EmptyStateView {
        EmptyStateView(
            icon: "doc.text.image",
            title: "No Receipts",
            message: "Upload receipts to see them here. Receipts are automatically processed and turned into transactions.",
            actionTitle: nil,
            action: nil
        )
    }
    
    static func noBadges() -> EmptyStateView {
        EmptyStateView(
            icon: "star",
            title: "No Badges Yet",
            message: "Start tracking your spending to earn your first badge! Upload receipts, create budgets, and reach savings goals.",
            actionTitle: nil,
            action: nil
        )
    }
    
    static func noTags() -> EmptyStateView {
        EmptyStateView(
            icon: "tag",
            title: "No Tags",
            message: "Create tags to organize your transactions. Tags help you categorize and filter your spending.",
            actionTitle: "Create Tag",
            action: nil
        )
    }
    
    static func noLinkedAccounts() -> EmptyStateView {
        EmptyStateView(
            icon: "creditcard",
            title: "No Linked Accounts",
            message: "Link your bank accounts to automatically track transactions and balances.",
            actionTitle: "Link Account",
            action: nil
        )
    }
}

