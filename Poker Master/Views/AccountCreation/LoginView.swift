import SwiftUI
import ActivityIndicatorView
import AuthenticationServices
import AlertToast

struct LoginView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager
    
    @State private var email: String = ""
    @State private var password: String = ""
    
    @State private var showToast: Bool = false
    
    let showCreateAccountCallback: () -> Void
    
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
                }
                .padding(.horizontal, 40)
                
                // MARK: Sign in button
                Button(action: {
                    authManager.signIn(email: email, password: password)
                }) {
                    HStack {
                        if authManager.isLoading {
                            ActivityIndicatorView(isVisible: .constant(true), type: .arcs(count: 3, lineWidth: 2))
                                .frame(width: 17, height: 17)
                        } else {
                            Text("Sign In")
                                .foregroundColor(email.isEmpty || password.isEmpty ? Color.gray.opacity(0.3) : Color.white.opacity(0.8))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(email.isEmpty || password.isEmpty ? Color.green.opacity(0.3) : Color.green.opacity(0.8))
                    .cornerRadius(10)
                }
                .padding(.horizontal, 40)
                .disabled(authManager.isLoading || email.isEmpty || password.isEmpty)
                
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
                    showCreateAccountCallback()
                }) {
                    Text("Don't have an account? Click here")
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
    LoginView(showCreateAccountCallback: {})
        .preferredColorScheme(.dark)
        .environmentObject(authManager)
}
