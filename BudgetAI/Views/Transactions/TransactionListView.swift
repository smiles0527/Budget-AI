//
//  TransactionListView.swift
//  BudgetAI
//
//  "Battle Log" - Transaction list view
//

import SwiftUI

// MARK: - Category Helpers

func txnIconForCategory(_ category: String) -> String {
    switch category.lowercased() {
    case "groceries": return "cart.fill"
    case "dining": return "fork.knife"
    case "transport": return "car.fill"
    case "shopping": return "bag.fill"
    case "entertainment": return "gamecontroller.fill"
    case "subscriptions": return "repeat.circle.fill"
    case "utilities": return "bolt.fill"
    case "health": return "heart.fill"
    case "education": return "book.fill"
    case "travel": return "airplane"
    case "income_adjustment": return "arrow.up.circle.fill"
    default: return "ellipsis.circle.fill"
    }
}

func txnColorForCategory(_ category: String) -> Color {
    switch category.lowercased() {
    case "groceries": return AppColors.primary
    case "dining": return .orange
    case "transport": return AppColors.rare
    case "shopping": return AppColors.epic
    case "entertainment": return .pink
    case "subscriptions": return AppColors.error
    case "utilities": return AppColors.accent
    case "health": return Color(hex: "#f472b6") ?? .pink
    case "education": return .indigo
    case "travel": return .cyan
    case "income_adjustment": return AppColors.success
    default: return .gray
    }
}

// MARK: - Main View

struct TransactionListView: View {
    @StateObject private var viewModel = TransactionsViewModel()
    @State private var searchText = ""
    @State private var showingFilters = false
    @State private var selectedCategory: String?
    @State private var startDate: Date?
    @State private var endDate: Date?
    @State private var minAmount: Double?
    @State private var maxAmount: Double?

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.backgroundDark.ignoresSafeArea()
                backgroundGlow
                mainContent
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingFilters) {
                TransactionFiltersView(
                    selectedCategory: $selectedCategory,
                    startDate: $startDate,
                    endDate: $endDate,
                    minAmount: $minAmount,
                    maxAmount: $maxAmount
                )
            }
            .onChange(of: selectedCategory) { _ in Task { await applyFilters() } }
            .onChange(of: startDate) { _ in Task { await applyFilters() } }
            .onChange(of: endDate) { _ in Task { await applyFilters() } }
            .onChange(of: minAmount) { _ in Task { await applyFilters() } }
            .onChange(of: maxAmount) { _ in Task { await applyFilters() } }
            .task { await viewModel.loadTransactions(refresh: true) }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Extracted Sub-views

    private var backgroundGlow: some View {
        ZStack {
            Circle()
                .fill(AppColors.primary.opacity(0.05))
                .frame(width: 400, height: 400)
                .blur(radius: 100)
                .offset(x: 150, y: -80)
            Circle()
                .fill(AppColors.epic.opacity(0.04))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: -120, y: 200)
            Circle()
                .fill(AppColors.rare.opacity(0.03))
                .frame(width: 250, height: 250)
                .blur(radius: 70)
                .offset(x: 50, y: 500)
        }
    }

    private var pageHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text("BATTLE LOG")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(1)
                Text("\(viewModel.transactions.count) encounters")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.4))
            }
            Spacer()
            Image(systemName: "scroll.fill")
                .font(.system(size: 18))
                .foregroundColor(AppColors.accent)
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 10) {
                pageHeader
                searchBar
                quickStats
                categoryChips
                transactionsList
                errorBanner
                Spacer().frame(height: 90)
            }
            .padding(.top, 4)
        }
        .refreshable {
            await viewModel.loadTransactions(refresh: true)
        }
    }

    private var searchBar: some View {
        BattleLogSearchBar(
            searchText: $searchText,
            showingFilters: $showingFilters,
            viewModel: viewModel
        )
        .padding(.horizontal)
    }

    private var quickStats: some View {
        Group {
            if !viewModel.transactions.isEmpty {
                let totalSpent = viewModel.transactions.reduce(0) { $0 + $1.total_cents }
                let catCount = Set(viewModel.transactions.map(\.category)).count
                BattleLogStatsBar(
                    battleCount: viewModel.transactions.count,
                    totalSpent: totalSpent,
                    categoryCount: catCount
                )
                .padding(.horizontal)
            }
        }
    }

    private var categoryChips: some View {
        Group {
            let grouped = Dictionary(grouping: viewModel.transactions, by: { $0.category })
            let breakdown = grouped.map { ($0.key, $0.value.count) }.sorted { $0.1 > $1.1 }
            if !breakdown.isEmpty {
                BattleLogCategoryChips(
                    breakdown: breakdown,
                    selectedCategory: $selectedCategory
                )
            }
        }
    }

    @ViewBuilder
    private var transactionsList: some View {
        if viewModel.isLoading && viewModel.transactions.isEmpty {
            skeletonCards
        } else if viewModel.transactions.isEmpty {
            emptyState
        } else {
            transactionCards
        }
    }

    private var skeletonCards: some View {
        VStack(spacing: 6) {
            ForEach(0..<5, id: \.self) { _ in
                TransactionCardSkeleton()
            }
        }
        .padding(.horizontal)
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(AppColors.primary.opacity(0.1))
                    .frame(width: 100, height: 100)
                Image(systemName: "scroll")
                    .font(.system(size: 44))
                    .foregroundColor(AppColors.primary.opacity(0.5))
            }
            Text("No Battle Records")
                .font(AppTypography.h3)
                .foregroundColor(.white)
            Text("Your quest log is empty.\nScan a receipt to record your first battle!")
                .font(AppTypography.body)
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private var transactionCards: some View {
        LazyVStack(spacing: 6) {
            ForEach(viewModel.transactions, id: \.id) { transaction in
                NavigationLink(destination: TransactionDetailView(transaction: transaction)) {
                    TransactionCard(transaction: transaction, viewModel: viewModel)
                }
                .buttonStyle(PlainButtonStyle())
            }
            if viewModel.hasMore {
                loadMoreButton
            }
        }
        .padding(.horizontal)
    }

    private var loadMoreButton: some View {
        Button(action: {
            Task { await viewModel.loadMore() }
        }) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 18))
                Text("Load More Battles")
                    .font(AppTypography.captionBold)
            }
            .foregroundColor(AppColors.primary)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(loadMoreBackground)
        }
    }

    private var loadMoreBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(AppColors.primary.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppColors.primary.opacity(0.3), lineWidth: 1)
            )
    }

    @ViewBuilder
    private var errorBanner: some View {
        if let error = viewModel.errorMessage {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(AppColors.error)
                Text(error)
                    .font(AppTypography.small)
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
                Button("Retry") {
                    Task { await viewModel.loadTransactions(refresh: true) }
                }
                .font(AppTypography.captionBold)
                .foregroundColor(AppColors.primary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.error.opacity(0.15))
            )
            .padding(.horizontal)
        }
    }

    private func applyFilters() async {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        await viewModel.loadTransactions(
            fromDate: startDate != nil ? formatter.string(from: startDate!) : nil,
            toDate: endDate != nil ? formatter.string(from: endDate!) : nil,
            category: selectedCategory,
            refresh: true
        )
    }
}

// MARK: - Search Bar

private struct BattleLogSearchBar: View {
    @Binding var searchText: String
    @Binding var showingFilters: Bool
    let viewModel: TransactionsViewModel

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppColors.primary)
                .font(.system(size: 16, weight: .semibold))

            TextField("Search the battle log...", text: $searchText)
                .textFieldStyle(.plain)
                .foregroundColor(.white)
                .font(AppTypography.body)
                .onSubmit { performSearch() }

            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    Task { await viewModel.loadTransactions(refresh: true) }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.4))
                }
            }

            filterButton
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(searchBackground)
    }

    private var filterButton: some View {
        Button(action: { showingFilters = true }) {
            Image(systemName: "slider.horizontal.3")
                .foregroundColor(AppColors.primary)
                .font(.system(size: 14, weight: .semibold))
                .padding(6)
                .background(AppColors.primary.opacity(0.15))
                .clipShape(Circle())
        }
    }

    private var searchBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.white.opacity(0.06))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppColors.primary.opacity(0.15), lineWidth: 1)
            )
    }

    private func performSearch() {
        Task {
            if !searchText.isEmpty {
                await viewModel.search(query: searchText)
            } else {
                await viewModel.loadTransactions(refresh: true)
            }
        }
    }
}

// MARK: - Stats Bar

private struct BattleLogStatsBar: View {
    let battleCount: Int
    let totalSpent: Int
    let categoryCount: Int

    var body: some View {
        HStack(spacing: 0) {
            StatBubble(icon: "flame.fill", value: "\(battleCount)", label: "Battles", color: AppColors.error)
            divider
            StatBubble(icon: "dollarsign.circle.fill", value: CurrencyFormatter.shared.format(cents: totalSpent), label: "Total", color: AppColors.accent)
            divider
            StatBubble(icon: "tag.fill", value: "\(categoryCount)", label: "Categories", color: AppColors.epic)
        }
        .padding(.vertical, 8)
        .background(statsBackground)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.1))
            .frame(width: 1, height: 24)
    }

    private var statsBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color.white.opacity(0.04))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
    }
}

private struct StatBubble: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundColor(color)
                Text(value)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            Text(label)
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Category Chips

private struct BattleLogCategoryChips: View {
    let breakdown: [(String, Int)]
    @Binding var selectedCategory: String?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                CategoryChip(
                    label: "All",
                    icon: "sparkles",
                    color: AppColors.primary,
                    isSelected: selectedCategory == nil,
                    action: { selectedCategory = nil }
                )
                ForEach(breakdown.prefix(6), id: \.0) { item in
                    CategoryChip(
                        label: item.0.capitalized,
                        icon: txnIconForCategory(item.0),
                        color: txnColorForCategory(item.0),
                        isSelected: selectedCategory == item.0,
                        action: {
                            selectedCategory = selectedCategory == item.0 ? nil : item.0
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
}

private struct CategoryChip: View {
    let label: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
                Text(label)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
            }
            .foregroundColor(isSelected ? .white : color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(chipBackground)
            .overlay(chipBorder)
        }
    }

    private var chipBackground: some View {
        Capsule().fill(isSelected ? color.opacity(0.35) : color.opacity(0.1))
    }

    private var chipBorder: some View {
        Capsule().stroke(isSelected ? color.opacity(0.6) : color.opacity(0.2), lineWidth: 1)
    }
}

// MARK: - Transaction Card

struct TransactionCard: View {
    let transaction: Transaction
    let viewModel: TransactionsViewModel

    private var catColor: Color { txnColorForCategory(transaction.category) }
    private var catIcon: String { txnIconForCategory(transaction.category) }
    private var isBigSpend: Bool { transaction.total_cents >= 5000 }

    var body: some View {
        HStack(spacing: 10) {
            iconBubble
            infoColumn
            Spacer()
            amountColumn
            chevron
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(cardBackground)
        .overlay(cardBorder)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(transaction.merchant ?? "Unknown"), \(transaction.category), \(viewModel.formatAmount(cents: transaction.total_cents))")
    }

    private var iconBubble: some View {
        ZStack {
            Circle()
                .fill(catColor.opacity(0.18))
                .frame(width: 36, height: 36)
            Image(systemName: catIcon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(catColor)
        }
        .shadow(color: catColor.opacity(0.35), radius: 4, y: 1)
    }

    private var infoColumn: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(transaction.merchant ?? "Unknown")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
            metadataRow
        }
    }

    private var metadataRow: some View {
        HStack(spacing: 4) {
            Text(transaction.category.capitalized)
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundColor(catColor)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(catColor.opacity(0.12)))

            Text(viewModel.formatDate(transaction.txn_date))
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.3))
        }
    }

    private var amountColumn: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(viewModel.formatAmount(cents: transaction.total_cents))
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(isBigSpend ? AppColors.error : catColor)
                .shadow(color: isBigSpend ? AppColors.error.opacity(0.4) : catColor.opacity(0.2), radius: 4)
            if isBigSpend {
                Text("CRIT!")
                    .font(.system(size: 8, weight: .black, design: .rounded))
                    .foregroundColor(AppColors.error)
                    .tracking(1)
            }
        }
    }

    private var chevron: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.white.opacity(0.2))
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(Color.white.opacity(0.05))
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 14)
            .stroke(
                isBigSpend ? AppColors.error.opacity(0.3) : catColor.opacity(0.08),
                lineWidth: 1
            )
    }
}

// MARK: - Skeleton Card

struct TransactionCardSkeleton: View {
    @State private var shimmer = false

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 36, height: 36)
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 110, height: 12)
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 70, height: 8)
            }
            Spacer()
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.white.opacity(0.08))
                .frame(width: 60, height: 14)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.03))
        )
        .opacity(shimmer ? 0.6 : 1.0)
        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: shimmer)
        .onAppear { shimmer = true }
    }
}

#Preview {
    TransactionListView()
}
