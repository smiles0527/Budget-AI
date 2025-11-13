//
//  TransactionsViewModel.swift
//  testapp
//
//  ViewModel for transactions list and management
//

import Foundation
import Combine

@MainActor
class TransactionsViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasMore = false
    
    private let apiClient = APIClient.shared
    private var currentCursor: String?
    private var isLoadingMore = false
    
    func loadTransactions(
        fromDate: String? = nil,
        toDate: String? = nil,
        category: String? = nil,
        refresh: Bool = false
    ) async {
        if refresh {
            currentCursor = nil
            transactions = []
        }
        
        guard !isLoadingMore else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiClient.getTransactions(
                limit: 50,
                cursor: currentCursor,
                fromDate: fromDate,
                toDate: toDate,
                category: category
            )
            
            if refresh {
                transactions = response.items
            } else {
                transactions.append(contentsOf: response.items)
            }
            
            currentCursor = response.next_cursor
            hasMore = response.next_cursor != nil
        } catch {
            errorMessage = ErrorHandler.userFriendlyMessage(for: error)
        }
        
        isLoading = false
    }
    
    func loadMore() async {
        guard hasMore, !isLoadingMore else { return }
        
        isLoadingMore = true
        
        do {
            let response = try await apiClient.getTransactions(
                limit: 50,
                cursor: currentCursor
            )
            
            transactions.append(contentsOf: response.items)
            currentCursor = response.next_cursor
            hasMore = response.next_cursor != nil
        } catch {
            errorMessage = ErrorHandler.userFriendlyMessage(for: error)
        }
        
        isLoadingMore = false
    }
    
    func search(query: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiClient.searchTransactions(query: query)
            transactions = response.items
            currentCursor = response.next_cursor
            hasMore = response.next_cursor != nil
        } catch {
            errorMessage = ErrorHandler.userFriendlyMessage(for: error)
        }
        
        isLoading = false
    }
    
    func formatAmount(cents: Int) -> String {
        return CurrencyFormatter.shared.format(cents: cents)
    }
    
    func formatDate(_ dateString: String) -> String {
        return dateString.toDisplayDate()
    }
    
    func updateTransaction(
        id: String,
        merchant: String,
        txnDate: String,
        totalCents: Int,
        taxCents: Int? = nil,
        tipCents: Int? = nil,
        category: String,
        subcategory: String? = nil
    ) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await apiClient.updateTransaction(
                id: id,
                merchant: merchant,
                txnDate: txnDate,
                totalCents: totalCents,
                taxCents: taxCents,
                tipCents: tipCents,
                category: category,
                subcategory: subcategory
            )
            // Reload transactions
            await loadTransactions(refresh: true)
        } catch {
            errorMessage = ErrorHandler.userFriendlyMessage(for: error)
        }
        
        isLoading = false
    }
    
    func createManualTransaction(
        merchant: String,
        txnDate: String,
        totalCents: Int,
        taxCents: Int? = nil,
        tipCents: Int? = nil,
        category: String? = nil,
        subcategory: String? = nil
    ) async {
        isLoading = true
        errorMessage = nil
        
        do {
            _ = try await apiClient.createManualTransaction(
                merchant: merchant,
                txnDate: txnDate,
                totalCents: totalCents,
                taxCents: taxCents,
                tipCents: tipCents,
                category: category,
                subcategory: subcategory
            )
            // Reload transactions
            await loadTransactions(refresh: true)
        } catch {
            errorMessage = ErrorHandler.userFriendlyMessage(for: error)
        }
        
        isLoading = false
    }
}

