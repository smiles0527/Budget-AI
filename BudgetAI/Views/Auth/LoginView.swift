//
//  LoginView.swift
//  BudgetAI
//
//  Gamified Login & Signup Screen
//

import SwiftUI

struct LoginView: View {
    @StateObject private var authManager = AuthManager.shared
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingSignup = false
    @Environment(\.dismiss) var dismiss
    
    // Custom TextField Style
    struct GamifiedFieldStyle: TextFieldStyle {
        func _body(configuration: TextField<Self._Label>) -> some View {
            configuration
                .padding()
                .background(Color.black.opacity(0.3))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .foregroundColor(.white)
                .font(AppTypography.body)
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                AppColors.backgroundDark
                    .ignoresSafeArea()
                
                // Grid Pattern (Simulated)
                Image(systemName: "grid") // Placeholder for pattern
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 800, height: 800)
                    .foregroundColor(AppColors.primary.opacity(0.03))
                    .rotationEffect(.degrees(45))
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        
                        // Header
                        VStack(spacing: 8) {
                            Text("Enter Realm")
                                .font(AppTypography.h1)
                                .foregroundColor(.white)
                                .shadow(color: AppColors.primary.opacity(0.5), radius: 10)
                            
                            Text("Resume your financial journey")
                                .font(AppTypography.body)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(.top, 40)
                        
                        // Main Card
                        VStack(spacing: 24) {
                            
                            // Avatar Placeholder
                            Circle()
                                .fill(LinearGradient(colors: [AppColors.primaryDark, AppColors.backgroundDark], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(AppColors.primary)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(AppColors.primary.opacity(0.5), lineWidth: 2)
                                )
                                .shadow(color: AppColors.primary.opacity(0.3), radius: 10)
                            
                            // Inputs
                            VStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("SCROLL ID (EMAIL)")
                                        .font(AppTypography.small)
                                        .foregroundColor(AppColors.primary)
                                        .tracking(1)
                                    
                                    TextField("wizard@example.com", text: $email)
                                        .textFieldStyle(GamifiedFieldStyle())
                                        .autocapitalization(.none)
                                        .keyboardType(.emailAddress)
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("SECRET RUNE (PASSWORD)")
                                        .font(AppTypography.small)
                                        .foregroundColor(AppColors.primary)
                                        .tracking(1)
                                    
                                    SecureField("••••••••", text: $password)
                                        .textFieldStyle(GamifiedFieldStyle())
                                }
                            }
                            
                            if let error = errorMessage {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(AppColors.error)
                                    Text(error)
                                        .font(AppTypography.caption)
                                        .foregroundColor(AppColors.error)
                                }
                                .padding()
                                .background(AppColors.error.opacity(0.1))
                                .cornerRadius(8)
                            }
                            
                            // Action Button
                            Button(action: handleLogin) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(AppColors.primaryGradient)
                                    
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        HStack {
                                            Text("Unlock Dashboard")
                                                .font(AppTypography.h4)
                                                .foregroundColor(.white)
                                            
                                            Image(systemName: "lock.open.fill")
                                                .foregroundColor(.white)
                                        }
                                    }
                                }
                                .frame(height: 56)
                                .shadow(color: AppColors.primary.opacity(0.4), radius: 8, y: 4)
                            }
                            .disabled(isLoading || email.isEmpty || password.isEmpty)
                            .opacity((isLoading || email.isEmpty || password.isEmpty) ? 0.6 : 1)
                        }
                        .padding(30)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color.white.opacity(0.05))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                        .padding(.horizontal, 20)
                        
                        // Footer
                        HStack {
                            Text("New to the guild?")
                                .font(AppTypography.body)
                                .foregroundColor(.white.opacity(0.6))
                            
                            Button("Forge Account") {
                                showingSignup = true
                            }
                            .font(AppTypography.bodyBold)
                            .foregroundColor(AppColors.accent)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingSignup) {
                SignupView()
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func handleLogin() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await authManager.login(email: email, password: password)
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

// Reuse similar style for Signup
struct SignupView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var authManager = AuthManager.shared
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    struct GamifiedFieldStyle: TextFieldStyle {
        func _body(configuration: TextField<Self._Label>) -> some View {
            configuration
                .padding()
                .background(Color.black.opacity(0.3))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .foregroundColor(.white)
                .font(AppTypography.body)
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.backgroundDark.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        VStack(spacing: 8) {
                            Text("Forge Account")
                                .font(AppTypography.h1)
                                .foregroundColor(.white)
                                .shadow(color: AppColors.secondary.opacity(0.5), radius: 10)
                            
                            Text("Begin your quest today")
                                .font(AppTypography.body)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(.top, 40)
                        
                        VStack(spacing: 24) {
                            VStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("SCROLL ID (EMAIL)")
                                        .font(AppTypography.small)
                                        .foregroundColor(AppColors.secondary)
                                        .tracking(1)
                                    TextField("wizard@example.com", text: $email)
                                        .textFieldStyle(GamifiedFieldStyle())
                                        .autocapitalization(.none)
                                        .keyboardType(.emailAddress)
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("SECRET RUNE (PASSWORD)")
                                        .font(AppTypography.small)
                                        .foregroundColor(AppColors.secondary)
                                        .tracking(1)
                                    SecureField("••••••••", text: $password)
                                        .textFieldStyle(GamifiedFieldStyle())
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("VERIFY RUNE")
                                        .font(AppTypography.small)
                                        .foregroundColor(AppColors.secondary)
                                        .tracking(1)
                                    SecureField("••••••••", text: $confirmPassword)
                                        .textFieldStyle(GamifiedFieldStyle())
                                }
                            }
                            
                            if let error = errorMessage {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(AppColors.error)
                                    Text(error)
                                        .font(AppTypography.caption)
                                        .foregroundColor(AppColors.error)
                                }
                                .padding()
                                .background(AppColors.error.opacity(0.1))
                                .cornerRadius(8)
                            }
                            
                            Button(action: handleSignup) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(LinearGradient(colors: [AppColors.secondary, AppColors.epic], startPoint: .leading, endPoint: .trailing))
                                    
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        HStack {
                                            Text("Create Character")
                                                .font(AppTypography.h4)
                                                .foregroundColor(.white)
                                            Image(systemName: "person.badge.plus")
                                                .foregroundColor(.white)
                                        }
                                    }
                                }
                                .frame(height: 56)
                                .shadow(color: AppColors.secondary.opacity(0.4), radius: 8, y: 4)
                            }
                            .disabled(isLoading || email.isEmpty || password.isEmpty || password != confirmPassword)
                            .opacity((isLoading || email.isEmpty || password.isEmpty || password != confirmPassword) ? 0.6 : 1)
                        }
                        .padding(30)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color.white.opacity(0.05))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                        .padding(.horizontal, 20)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func handleSignup() {
        guard password == confirmPassword else {
            errorMessage = "Runes do not match (Passwords must match)"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await authManager.signup(email: email, password: password)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

#Preview {
    LoginView()
}

