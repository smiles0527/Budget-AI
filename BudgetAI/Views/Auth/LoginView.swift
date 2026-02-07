//
//  LoginView.swift
//  BudgetAI
//
//  Gamified Login & Signup Screen
//

import SwiftUI

struct LoginView: View {
    @ObservedObject private var authManager = AuthManager.shared
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
                .font(.system(size: 15))
                .frame(minHeight: 44)
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                AppColors.backgroundDark
                    .ignoresSafeArea()
                
                // Grid Pattern (Simulated) - constrained to screen
                GeometryReader { geometry in
                    Image(systemName: "grid")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width * 1.5, height: geometry.size.height * 1.5)
                        .foregroundColor(AppColors.primary.opacity(0.03))
                        .rotationEffect(.degrees(45))
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)
                
                ScrollView {
                    VStack(spacing: 20) {
                        
                        // Header
                        VStack(spacing: 8) {
                            Text("Enter Realm")
                                .font(.system(size: 24, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text("Resume your financial journey")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.top, 20)
                        
                        // Main Card
                        VStack(alignment: .leading, spacing: 16) {
                            
                            // Avatar
                            Circle()
                                .fill(AppColors.primary.opacity(0.2))
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(AppColors.primary)
                                )
                                .frame(maxWidth: .infinity, alignment: .center)
                            
                            // Inputs
                            VStack(alignment: .leading, spacing: 12) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("EMAIL")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(AppColors.primary)
                                    
                                    TextField("wizard@example.com", text: $email)
                                        .textFieldStyle(GamifiedFieldStyle())
                                        .textContentType(.emailAddress)
                                        .autocapitalization(.none)
                                        .keyboardType(.emailAddress)
                                }
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("PASSWORD")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(AppColors.primary)
                                    
                                    SecureField("••••••••", text: $password)
                                        .textFieldStyle(GamifiedFieldStyle())
                                        .textContentType(.password)
                                }
                            }
                            
                            if let error = errorMessage {
                                HStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(AppColors.error)
                                        .font(.system(size: 14))
                                    Text(error)
                                        .font(.system(size: 13))
                                        .foregroundColor(AppColors.error)
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(AppColors.error.opacity(0.1))
                                .cornerRadius(8)
                            }
                            
                            // Action Button
                            Button(action: handleLogin) {
                                HStack {
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Text("Unlock Dashboard")
                                            .font(.system(size: 16, weight: .bold))
                                        Image(systemName: "lock.open.fill")
                                    }
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(AppColors.primaryGradient)
                                .cornerRadius(12)
                            }
                            .disabled(isLoading || email.isEmpty || password.isEmpty)
                            .opacity((isLoading || email.isEmpty || password.isEmpty) ? 0.6 : 1)
                        }
                        .padding(20)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(20)
                        
                        // Footer
                        HStack {
                            Text("New to the guild?")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.6))
                            
                            Button("Forge Account") {
                                showingSignup = true
                            }
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AppColors.accent)
                        }
                    }
                    .padding(.horizontal, 20)
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
    @ObservedObject private var authManager = AuthManager.shared
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
                .font(.system(size: 15))
                .frame(minHeight: 44)
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.backgroundDark.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        VStack(spacing: 8) {
                            Text("Forge Account")
                                .font(.system(size: 24, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text("Begin your quest today")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.top, 20)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            VStack(alignment: .leading, spacing: 12) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("EMAIL")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(AppColors.secondary)
                                    TextField("wizard@example.com", text: $email)
                                        .textFieldStyle(GamifiedFieldStyle())
                                        .textContentType(.emailAddress)
                                        .autocapitalization(.none)
                                        .keyboardType(.emailAddress)
                                        .tint(AppColors.primary)
                                }
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("PASSWORD")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(AppColors.secondary)
                                    SecureField("••••••••", text: $password)
                                        .textFieldStyle(GamifiedFieldStyle())
                                        .textContentType(.newPassword)
                                        .tint(AppColors.primary)
                                }
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("CONFIRM PASSWORD")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(AppColors.secondary)
                                    SecureField("••••••••", text: $confirmPassword)
                                        .textFieldStyle(GamifiedFieldStyle())
                                        .textContentType(.newPassword)
                                        .tint(AppColors.primary)
                                }
                            }
                            
                            if let error = errorMessage {
                                HStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(AppColors.error)
                                        .font(.system(size: 14))
                                    Text(error)
                                        .font(.system(size: 13))
                                        .foregroundColor(AppColors.error)
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(AppColors.error.opacity(0.1))
                                .cornerRadius(8)
                            }
                            
                            Button(action: handleSignup) {
                                HStack {
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Text("Create Character")
                                            .font(.system(size: 16, weight: .bold))
                                        Image(systemName: "person.badge.plus")
                                    }
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(LinearGradient(colors: [AppColors.secondary, AppColors.epic], startPoint: .leading, endPoint: .trailing))
                                .cornerRadius(12)
                            }
                            .disabled(isLoading || email.isEmpty || password.isEmpty || password != confirmPassword)
                            .opacity((isLoading || email.isEmpty || password.isEmpty || password != confirmPassword) ? 0.6 : 1)
                        }
                        .padding(20)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(20)
                    }
                    .padding(.horizontal, 20)
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

