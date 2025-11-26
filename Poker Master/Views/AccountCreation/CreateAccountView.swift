//
//  CreateAccountView.swift
//  Poker Master
//
//  Created by Ned Whittleton on 9/19/25.
//

import SwiftUI
import ActivityIndicatorView
import AuthenticationServices
import AlertToast

struct CreateAccountView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    
    @State private var passwordError: String? = nil
    
    @State private var showToast: Bool = false
    
    let showLoginCallback: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30,) {
                // App Logo or Title
                VStack(spacing: 8) {
                    Text("Poker Master")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Sharpen your poker decisions")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.top, 60)
                
                // Email + Password fields
                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .padding()
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(10)
                        .foregroundColor(.white)
                    
                    
                    SecureField("Password", text: $password)
                        .padding()
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(10)
                        .foregroundColor(.white)
                    
                    SecureField("Confirm Password", text: $confirmPassword)
                        .padding()
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(10)
                        .foregroundColor(.white)

                    if let error = passwordError {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.top, -10)
                    } else {
                        Color.clear.frame(height: 0)
                    }
                }
                .padding(.horizontal, 40)
                
                // MARK: Sign up button
                Button(action: {
                    passwordError = nil  // clear old errors

                    guard password == confirmPassword else {
                        passwordError = "Passwords do not match."
                        return
                    }
                    
                    authManager.signUp(email: email, password: password)
                }) {
                    HStack {
                        if authManager.isLoading {
                            ActivityIndicatorView(isVisible: .constant(true), type: .arcs(count: 3, lineWidth: 2))
                                .frame(width: 17, height: 17)
                        } else {
                            Text("Create Account")
                                .foregroundColor(email.isEmpty || password.isEmpty || confirmPassword.isEmpty ? Color.gray.opacity(0.3) : Color.white.opacity(0.8))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(email.isEmpty || password.isEmpty || confirmPassword.isEmpty ? Color.green.opacity(0.3) : Color.green.opacity(0.8))
                    .cornerRadius(10)
                }
                .padding(.horizontal, 40)
                .disabled(authManager.isLoading || email.isEmpty || password.isEmpty || confirmPassword.isEmpty)
                
                // Divider
                HStack {
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(.gray.opacity(0.5))
                    Text("or")
                        .foregroundColor(.gray)
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(.gray.opacity(0.5))
                }
                .padding(.horizontal, 40)
                
                // Third-party sign in buttons
                SignInWithAppleButton(
                    onRequest: authManager.prepareAppleRequest,
                    onCompletion: authManager.handleAppleCompletion
                )
                .signInWithAppleButtonStyle(.white)
                .frame(height: 52)
                .cornerRadius(12)
                .padding(.horizontal, 40)
                Button(action: {
                    dismiss()
                    showLoginCallback()
                }) {
                    Text("Already have an account? Log In")
                        .foregroundColor(.white.opacity(0.8))
                        .underline()
                }
                Spacer()
                
                Button(action: {
                    dismiss()
                }) {
                    Text("Not now")
                        .foregroundColor(.white)
                        .underline()
                }
            }
            .onReceive(authManager.$errorMessage) { msg in
                if msg != nil { showToast = true }
            }
            .toast(
                isPresenting: $showToast,
                duration: 10,
                tapToDismiss: true,
                alert: {
                    AlertToast(
                        displayMode: .hud,
                        type: .error(.red),
                        title: authManager.errorMessage,
                        subTitle: nil
                    )
                },
                completion: {
                    DispatchQueue.main.async {
                        showToast = false
                        authManager.errorMessage = nil
                    }
                }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .preferredColorScheme(.dark)
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .onChange(of: authManager.isAuthenticated) { _, isAuthenticated in
                if isAuthenticated {
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    @Previewable @StateObject var authManager = AuthManager()
    return CreateAccountView(showLoginCallback: {})
        .environmentObject(authManager)
}
