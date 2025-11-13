//
//  DeleteAccountView.swift
//  testapp
//
//  Account deletion confirmation
//

import SwiftUI

struct DeleteAccountView: View {
    @StateObject private var authManager = AuthManager.shared
    @State private var showingConfirmation = false
    @State private var confirmationText = ""
    @State private var isDeleting = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        Form {
            Section {
                Text("Deleting your account will permanently remove all your data including transactions, budgets, savings goals, and receipts. This action cannot be undone.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Section {
                TextField("Type 'DELETE' to confirm", text: $confirmationText)
                
                Button(action: { showingConfirmation = true }) {
                    HStack {
                        if isDeleting {
                            ProgressView()
                        } else {
                            Image(systemName: "trash.fill")
                        }
                        Text("Delete Account")
                    }
                    .foregroundColor(.red)
                }
                .disabled(confirmationText != "DELETE" || isDeleting)
            }
            
            if let error = errorMessage {
                Section {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
        }
        .navigationTitle("Delete Account")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete Account", isPresented: $showingConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteAccount()
            }
        } message: {
            Text("Are you absolutely sure? This will permanently delete your account and all associated data. This action cannot be undone.")
        }
    }
    
    private func deleteAccount() {
        isDeleting = true
        errorMessage = nil
        
        Task {
            do {
                try await APIClient.shared.deleteAccount()
                await authManager.logout()
                // Dismiss will happen automatically after logout
            } catch {
                errorMessage = ErrorHandler.userFriendlyMessage(for: error)
                isDeleting = false
            }
        }
    }
}

#Preview {
    NavigationView {
        DeleteAccountView()
    }
}

