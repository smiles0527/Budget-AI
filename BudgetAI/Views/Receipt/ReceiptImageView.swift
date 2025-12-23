//
//  ReceiptImageView.swift
//  testapp
//
//  Full-screen receipt image viewer
//

import SwiftUI

struct ReceiptImageView: View {
    let imageURL: String
    @Environment(\.dismiss) var dismiss
    @State private var image: UIImage?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .ignoresSafeArea()
                } else if let errorMessage = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.white.opacity(0.7))
                        Text(errorMessage)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Receipt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .task {
                await loadImage()
            }
        }
    }
    
    private func loadImage() async {
        guard let url = URL(string: imageURL) else {
            errorMessage = "Invalid image URL"
            isLoading = false
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
                    self.errorMessage = "Failed to load image"
                    self.isLoading = false
                }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load image: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
}

#Preview {
    ReceiptImageView(imageURL: "https://example.com/receipt.jpg")
}

