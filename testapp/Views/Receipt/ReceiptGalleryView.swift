//
//  ReceiptGalleryView.swift
//  testapp
//
//  Gallery view showing all receipt images
//

import SwiftUI

struct ReceiptGalleryView: View {
    @StateObject private var viewModel = ReceiptGalleryViewModel()
    @State private var selectedReceipt: ReceiptWithTransaction?
    @State private var showingReceiptImage = false
    
    let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 2)
    
    var body: some View {
        ScrollView {
            if viewModel.isLoading && viewModel.receipts.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 100)
            } else if viewModel.receipts.isEmpty {
                EmptyStateView.noReceipts()
            } else {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(viewModel.receipts, id: \.receipt.id) { receiptWithTxn in
                        ReceiptThumbnail(
                            receiptWithTxn: receiptWithTxn,
                            onTap: {
                                selectedReceipt = receiptWithTxn
                                showingReceiptImage = true
                            }
                        )
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Receipt Gallery")
        .navigationBarTitleDisplayMode(.large)
        .refreshable {
            await viewModel.loadReceipts()
        }
        .sheet(isPresented: $showingReceiptImage) {
            if let receiptWithTxn = selectedReceipt,
               let imageURL = receiptWithTxn.receipt.image_url {
                ReceiptImageView(imageURL: imageURL)
            }
        }
        .task {
            await viewModel.loadReceipts()
        }
    }
}

struct ReceiptThumbnail: View {
    let receiptWithTxn: ReceiptWithTransaction
    let onTap: () -> Void
    @State private var image: UIImage?
    @State private var isLoading = true
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .aspectRatio(0.75, contentMode: .fit)
                
                if isLoading {
                    ProgressView()
                } else if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "doc.text.image")
                            .font(.system(size: 30))
                            .foregroundColor(.secondary)
                        Text("No Image")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Overlay with merchant and date
                VStack {
                    Spacer()
                    VStack(alignment: .leading, spacing: 4) {
                        if let merchant = receiptWithTxn.transaction.merchant {
                            Text(merchant)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .lineLimit(1)
                        }
                        Text(receiptWithTxn.transaction.txn_date.toDisplayDate())
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(
                        LinearGradient(
                            colors: [Color.black.opacity(0.7), Color.clear],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .task {
            await loadImage()
        }
    }
    
    private func loadImage() async {
        guard let imageURL = receiptWithTxn.receipt.image_url,
              let url = URL(string: imageURL) else {
            await MainActor.run {
                isLoading = false
            }
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let uiImage = UIImage(data: data) {
                await MainActor.run {
                    self.image = uiImage
                    self.isLoading = false
                }
            } else {
                await MainActor.run {
                    self.isLoading = false
                }
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
}

struct ReceiptWithTransaction: Identifiable {
    let id: String { receipt.id }
    let receipt: Receipt
    let transaction: Transaction
}

@MainActor
class ReceiptGalleryViewModel: ObservableObject {
    @Published var receipts: [ReceiptWithTransaction] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiClient = APIClient.shared
    
    func loadReceipts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Get all transactions
            let transactionsResponse = try await apiClient.getTransactions(limit: 1000)
            
            // Filter transactions that have receipts
            let transactionsWithReceipts = transactionsResponse.items.filter { $0.receipt_id != nil }
            
            // Fetch receipt details for each transaction
            var receiptsWithTransactions: [ReceiptWithTransaction] = []
            
            for transaction in transactionsWithReceipts {
                if let receiptId = transaction.receipt_id {
                    do {
                        let receipt = try await apiClient.getReceipt(id: receiptId)
                        // Only include receipts that have images
                        if receipt.image_url != nil {
                            receiptsWithTransactions.append(
                                ReceiptWithTransaction(receipt: receipt, transaction: transaction)
                            )
                        }
                    } catch {
                        // Skip receipts that can't be loaded
                        continue
                    }
                }
            }
            
            // Sort by transaction date (newest first)
            receipts = receiptsWithTransactions.sorted { receipt1, receipt2 in
                receipt1.transaction.txn_date > receipt2.transaction.txn_date
            }
        } catch {
            errorMessage = ErrorHandler.userFriendlyMessage(for: error)
        }
        
        isLoading = false
    }
}

#Preview {
    NavigationView {
        ReceiptGalleryView()
    }
}

