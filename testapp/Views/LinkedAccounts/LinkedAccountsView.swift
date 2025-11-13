//
//  LinkedAccountsView.swift
//  testapp
//
//  Linked accounts management
//

import SwiftUI

struct LinkedAccountsView: View {
    @StateObject private var viewModel = LinkedAccountsViewModel()
    @State private var showingAddAccount = false
    
    var body: some View {
        List {
            if viewModel.isLoading && viewModel.accounts.isEmpty {
                ProgressView()
            } else if viewModel.accounts.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "creditcard")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    Text("No linked accounts")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Link your bank accounts to track balances")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                ForEach(viewModel.accounts, id: \.id) { account in
                    NavigationLink(destination: LinkedAccountDetailView(account: account, viewModel: viewModel)) {
                        LinkedAccountRow(account: account)
                    }
                }
            }
            
            if let error = viewModel.errorMessage {
                Section {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
        }
        .navigationTitle("Linked Accounts")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Add") {
                    showingAddAccount = true
                }
            }
        }
        .sheet(isPresented: $showingAddAccount) {
            AddLinkedAccountView(viewModel: viewModel)
        }
        .refreshable {
            await viewModel.loadAccounts()
        }
        .task {
            await viewModel.loadAccounts()
        }
    }
}

struct LinkedAccountRow: View {
    let account: LinkedAccount
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(account.institution_name)
                    .font(.headline)
                Spacer()
                if let balance = account.balance, let current = balance.current_cents {
                    Text(CurrencyFormatter.shared.format(cents: current))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
            
            Text(account.account_name)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                Text(account.account_type.capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let mask = account.account_mask {
                    Text("• \(mask)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(account.status.capitalized)
                    .font(.caption)
                    .foregroundColor(account.status == "active" ? .green : .orange)
            }
        }
        .padding(.vertical, 4)
    }
}

struct LinkedAccountDetailView: View {
    let account: LinkedAccount
    @ObservedObject var viewModel: LinkedAccountsViewModel
    @State private var showingUpdateBalance = false
    @State private var showingDeleteAlert = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        List {
            Section("Account Details") {
                HStack {
                    Text("Institution")
                    Spacer()
                    Text(account.institution_name)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Account Name")
                    Spacer()
                    Text(account.account_name)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Type")
                    Spacer()
                    Text(account.account_type.capitalized)
                        .foregroundColor(.secondary)
                }
                
                if let subtype = account.account_subtype {
                    HStack {
                        Text("Subtype")
                        Spacer()
                        Text(subtype.capitalized)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let mask = account.account_mask {
                    HStack {
                        Text("Account Mask")
                        Spacer()
                        Text(mask)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    Text("Status")
                    Spacer()
                    Text(account.status.capitalized)
                        .foregroundColor(account.status == "active" ? .green : .orange)
                }
            }
            
            if let balance = account.balance {
                Section("Balance") {
                    if let current = balance.current_cents {
                        HStack {
                            Text("Current Balance")
                            Spacer()
                            Text(CurrencyFormatter.shared.format(cents: current))
                                .fontWeight(.semibold)
                        }
                    }
                    
                    if let available = balance.available_cents {
                        HStack {
                            Text("Available Balance")
                            Spacer()
                            Text(CurrencyFormatter.shared.format(cents: available))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Text("Currency")
                        Spacer()
                        Text(balance.currency_code)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("As of")
                        Spacer()
                        Text(balance.as_of.toDisplayDate())
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section {
                Button(action: { showingUpdateBalance = true }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Update Balance")
                    }
                    .foregroundColor(.blue)
                }
                
                Button(action: { showingDeleteAlert = true }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Unlink Account")
                    }
                    .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("Account Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingUpdateBalance) {
            UpdateBalanceView(accountId: account.id, viewModel: viewModel)
        }
        .alert("Unlink Account", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Unlink", role: .destructive) {
                Task {
                    await viewModel.deleteAccount(id: account.id)
                    dismiss()
                }
            }
        } message: {
            Text("Are you sure you want to unlink this account? This will remove it from your account list.")
        }
    }
}

@MainActor
class LinkedAccountsViewModel: ObservableObject {
    @Published var accounts: [LinkedAccount] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiClient = APIClient.shared
    
    func loadAccounts(status: String? = nil) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiClient.getLinkedAccounts(status: status)
            accounts = response.items
        } catch {
            errorMessage = ErrorHandler.userFriendlyMessage(for: error)
        }
        
        isLoading = false
    }
    
    func createAccount(
        provider: String,
        providerAccountId: String,
        institutionName: String,
        accountMask: String?,
        accountName: String,
        accountType: String,
        accountSubtype: String?
    ) async {
        isLoading = true
        errorMessage = nil
        
        do {
            _ = try await apiClient.createLinkedAccount(
                provider: provider,
                providerAccountId: providerAccountId,
                institutionName: institutionName,
                accountMask: accountMask,
                accountName: accountName,
                accountType: accountType,
                accountSubtype: accountSubtype
            )
            await loadAccounts()
        } catch {
            errorMessage = ErrorHandler.userFriendlyMessage(for: error)
        }
        
        isLoading = false
    }
    
    func updateBalance(
        accountId: String,
        currentCents: Int?,
        availableCents: Int?,
        currencyCode: String = "USD"
    ) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await apiClient.updateLinkedAccountBalance(
                accountId: accountId,
                currentCents: currentCents,
                availableCents: availableCents,
                currencyCode: currencyCode
            )
            await loadAccounts()
        } catch {
            errorMessage = ErrorHandler.userFriendlyMessage(for: error)
        }
        
        isLoading = false
    }
    
    func deleteAccount(id: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await apiClient.deleteLinkedAccount(id: id)
            await loadAccounts()
        } catch {
            errorMessage = ErrorHandler.userFriendlyMessage(for: error)
        }
        
        isLoading = false
    }
}

struct AddLinkedAccountView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: LinkedAccountsViewModel
    @State private var institutionName = ""
    @State private var accountName = ""
    @State private var accountMask = ""
    @State private var accountType = "checking"
    @State private var accountSubtype = ""
    @State private var provider = "manual"
    @State private var providerAccountId = ""
    @State private var errorMessage: String?
    
    let accountTypes = ["checking", "savings", "credit", "investment", "loan", "other"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Account Information") {
                    TextField("Institution Name", text: $institutionName)
                    TextField("Account Name", text: $accountName)
                    TextField("Account Mask (last 4 digits)", text: $accountMask)
                        .keyboardType(.numberPad)
                    
                    Picker("Account Type", selection: $accountType) {
                        ForEach(accountTypes, id: \.self) { type in
                            Text(type.capitalized).tag(type)
                        }
                    }
                    
                    TextField("Subtype (optional)", text: $accountSubtype)
                }
                
                Section("Provider Details") {
                    TextField("Provider", text: $provider)
                    TextField("Provider Account ID", text: $providerAccountId)
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Link Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveAccount()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
    
    private var isValid: Bool {
        return !institutionName.isEmpty && !accountName.isEmpty
    }
    
    private func saveAccount() {
        guard !institutionName.isEmpty && !accountName.isEmpty else {
            errorMessage = "Please fill in required fields"
            return
        }
        
        errorMessage = nil
        
        Task {
            await viewModel.createAccount(
                provider: provider.isEmpty ? "manual" : provider,
                providerAccountId: providerAccountId.isEmpty ? UUID().uuidString : providerAccountId,
                institutionName: institutionName,
                accountMask: accountMask.isEmpty ? nil : accountMask,
                accountName: accountName,
                accountType: accountType,
                accountSubtype: accountSubtype.isEmpty ? nil : accountSubtype
            )
            dismiss()
        }
    }
}

struct UpdateBalanceView: View {
    @Environment(\.dismiss) var dismiss
    let accountId: String
    @ObservedObject var viewModel: LinkedAccountsViewModel
    @State private var currentDollars = ""
    @State private var availableDollars = ""
    @State private var currencyCode = "USD"
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            Form {
                Section("Balance") {
                    TextField("Current Balance ($)", text: $currentDollars)
                        .keyboardType(.decimalPad)
                    
                    TextField("Available Balance ($)", text: $availableDollars)
                        .keyboardType(.decimalPad)
                    
                    TextField("Currency Code", text: $currencyCode)
                        .autocapitalization(.allCharacters)
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Update Balance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveBalance()
                    }
                }
            }
        }
    }
    
    private func saveBalance() {
        errorMessage = nil
        
        Task {
            await viewModel.updateBalance(
                accountId: accountId,
                currentCents: currentDollars.isEmpty ? nil : Int((Double(currentDollars) ?? 0) * 100),
                availableCents: availableDollars.isEmpty ? nil : Int((Double(availableDollars) ?? 0) * 100),
                currencyCode: currencyCode
            )
            dismiss()
        }
    }
}

#Preview {
    NavigationView {
        LinkedAccountsView()
    }
}

