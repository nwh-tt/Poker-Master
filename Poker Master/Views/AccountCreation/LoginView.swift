import SwiftUI
import AuthenticationServices
import AnimatedGradient

struct LoginView: View {
    @AppStorage("isSignedIn") private var isSignedIn: Bool = false
    @Environment(\.dismiss) var dismiss   // <-- add this
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // App Logo or Title
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "suit.club.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.green)
                }
                
                Text("Poker Master")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Sharpen your poker decisions")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding(.top, 60)
            
            Spacer()
            
            // Apple Sign In Button
            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                switch result {
                case .success(let authResults):
                    self.handleAppleSignIn(authResults)
                    isSignedIn = true
                case .failure(let error):
                    print("Authorization failed: \(error.localizedDescription)")
                }
            }
            .signInWithAppleButtonStyle(.white) // .black, .whiteOutline also available
            .frame(height: 50)
            .cornerRadius(10)
            .padding(.horizontal, 40)
            
            Button(action: {
                dismiss()
            }) {
                Text("Not now")
                    .foregroundColor(.white)
                    .underline()
            }
            
            Text("We use your Apple ID to authenticate you, protect your progress, and confirm any subscriptions.")
                .font(.footnote)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
        .background(
            AnimatedLinearGradient(colors: [.black, Color(red: 30/255, green: 90/255, blue: 60/255), Color.black])
                .setAnimation(.linear(duration: 5))
            .ignoresSafeArea()
        )
    }
    
    private func handleAppleSignIn(_ authResults: ASAuthorization) {
            guard let appleIDCredential = authResults.credential as? ASAuthorizationAppleIDCredential else {
                print("Unable to get AppleID Credential")
                return
            }
            
            // Get identity token as string
            if let identityTokenData = appleIDCredential.identityToken,
               let identityTokenString = String(data: identityTokenData, encoding: .utf8) {
                
                // Save token permanently using Keychain via LoginService
                let saved = LoginService.shared.saveToken(identityTokenString)
                print("Token saved permanently:", saved)
                
                // Optional: store userIdentifier if you want to track the user
                let userId = appleIDCredential.user
                print("Apple userIdentifier:", userId)
                
                // Update app state
                // isSignedIn = true
            } else {
                print("Failed to get identity token from AppleIDCredential")
            }
        }
}

#Preview {
    LoginView()
        .preferredColorScheme(.dark)
}
