import Foundation
import AuthenticationServices
import FirebaseAuth
import CryptoKit
import RevenueCat

class AuthManager: ObservableObject {
    @Published var user: User? // The current authenticated user
    @Published var isAuthenticated: Bool = false
    
    // States to handle the UI
    @Published var errorMessage: String? = nil
    @Published var isLoading: Bool = false
    
    private var currentNonce: String?

    init() {
            // Listen for changes in the authentication state
            Auth.auth().addStateDidChangeListener { [weak self] _, user in
                self?.user = user
                self?.isAuthenticated = user != nil
                
                if let user = user {
                    let firebaseUID = user.uid
                    Purchases.shared.logIn(firebaseUID) { customerInfo, created, error in
                        if let error = error {
                            print("❌ Failed to log in to RevenueCat: \(error.localizedDescription)")
                        } else {
                            print("✅ Linked Firebase user to RevenueCat with UID: \(firebaseUID)")
                            print("Customer info: \(String(describing: customerInfo))")
                            print("New RevenueCat user created: \(created)")
                        }
                    }
                } else {
                    // User is signed out set isAuthenticated to false
                    self?.isAuthenticated = false
                    slelf?.user = nil
                    
                    // If user signs out, log out of RevenueCat too
                    Purchases.shared.logOut { customerInfo, error in
                        if let error = error {
                            print("⚠️ RevenueCat logout failed: \(error.localizedDescription)")
                        } else {
                            print("👋 Logged out of RevenueCat.")
                        }
                    }
                }
            }
        }
    
    func getIDToken(forceRefresh: Bool = false) async throws -> String {
        // 1. Check if a user is currently signed in.
        guard let user = Auth.auth().currentUser else {
            // Throw an error if no user is authenticated
            throw TokenError.userNotAuthenticated
        }
        
        do {
            // 2. Fetch the ID Token asynchronously.
            // forceRefresh=true ensures the token is fresh, but often
            // set to false unless an immediate refresh is needed.
            let token = try await user.getIDTokenResult(forcingRefresh: forceRefresh).token
            
            // 3. Return the token string
            return token
            
        } catch {
            // 4. Handle token retrieval failure (e.g., network error)
            print("Failed to retrieve ID Token: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Sign In
    func signIn(email: String, password: String) {
        errorMessage = nil // Clear any previous errors
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            if let error = error {
                // Handle sign-in failure (e.g., incorrect password, no user)
                print("Firebase sign-in error: \(error.localizedDescription)")
                self?.errorMessage = "Username or password incorrect"
                self?.isAuthenticated = false
            } else {
                // Sign-in successful
                print("User signed in with UID: \(authResult?.user.uid ?? "N/A")")
                self?.isAuthenticated = true
                
                // TODO: Here you would also create/fetch your AppUser SwiftData model
                // based on the successful Firebase sign-in.
            }
        }
    }
    
    
    // MARK: - Sign Up (User Creation)
    func signUp(email: String, password: String) {
        errorMessage = nil
        isLoading = true
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResult, error in
            DispatchQueue.main.async { // Ensure UI updates are on the main thread
                self?.isLoading = false
                if let error = error {
                    // Sign-up failed
                    self?.errorMessage = "Sign-up failed"
                    self?.isAuthenticated = false
                } else {
                    // Sign-up succeeded, user is automatically logged in
                    print("New user created: \(authResult?.user.uid ?? "N/A")")
                    self?.isAuthenticated = true
                    // The view will automatically dismiss/transition because isAuthenticated changed
                }
            }
        }
    }
       
       // MARK: - Sign Out
    func signOut() {
        do {
            try Auth.auth().signOut()
            isAuthenticated = false
        } catch let error {
            errorMessage = error.localizedDescription
        }
    }
    
    func prepareAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = appleSignInRandomNonceString()
        currentNonce = nonce
        
        request.requestedScopes = [.email, .fullName]
        request.nonce = sha256(nonce)
    }
    
    func handleAppleCompletion(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authResults):
            guard let appleIDCredential = authResults.credential as? ASAuthorizationAppleIDCredential else {
                errorMessage = "Unable to read token"
                return
            }
            signInWithAppleCredential(appleIDCredential)
            
        case .failure(let error):
            errorMessage = "Apple Sign-in failed"
            print("Apple Sign-in failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Step 3: Convert to Firebase Credential & Sign In

    private func signInWithAppleCredential(_ appleIDCredential: ASAuthorizationAppleIDCredential) {
        guard let nonce = currentNonce else {
            errorMessage = "Please try again"
            return
        }
        
        guard let appleIDToken = appleIDCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            errorMessage = "Please try again"
            print("Failed to get token from AppleIDCredential")
            return
        }
        
        let credential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: appleIDCredential.fullName
        )
        
        Auth.auth().signIn(with: credential) { [weak self] (authResult, error) in
            if let error = error {
                print("Firebase sign-in error: \(error.localizedDescription)")
                self?.errorMessage = "Firebase sign-in error"
                return
            }
            self?.isAuthenticated = true
        }
    }
    
    // MARK: Apple Sign in functions
    private func appleSignInRandomNonceString(length: Int = 32) -> String {
      precondition(length > 0)
      var randomBytes = [UInt8](repeating: 0, count: length)
      let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
      if errorCode != errSecSuccess {
        fatalError(
          "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
        )
      }

      let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")

      let nonce = randomBytes.map { byte in
        // Pick a random character from the set, wrapping around if needed.
        charset[Int(byte) % charset.count]
      }

      return String(nonce)
    }

    @available(iOS 13, *)
    private func sha256(_ input: String) -> String {
      let inputData = Data(input.utf8)
      let hashedData = SHA256.hash(data: inputData)
      let hashString = hashedData.compactMap {
        String(format: "%02x", $0)
      }.joined()

      return hashString
    }
    
    
}

// Custom error to make token retrieval errors clear
enum TokenError: Error, LocalizedError {
    case userNotAuthenticated
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "Not Authenticated"
        }
    }
}
