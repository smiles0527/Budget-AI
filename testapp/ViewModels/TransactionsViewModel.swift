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
            errorMessage = error.localizedDescription
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
            errorMessage = error.localizedDescription
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
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func formatAmount(cents: Int) -> String {
        let dollars = Double(cents) / 100.0
        return String(format: "$%.2f", dollars)
    }
    
    func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]
        
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .none
            return displayFormatter.string(from: date)
        }
        
        return dateString
    }
}

