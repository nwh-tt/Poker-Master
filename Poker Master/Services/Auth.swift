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
                self?.errorMessage = error.localizedDescription
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
                    self?.errorMessage = error.localizedDescription
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
    
    // MARK: Apple Sign in functions
    func signInWithApple(credential: AuthCredential) {
        Auth.auth().signIn(with: credential) { (authResult, error) in
            if (error != nil) {
                // Error. If error.code == .MissingOrInvalidNonce, make sure
                // you're sending the SHA256-hashed nonce as a hex string with
                // your request to Apple.
                print(error?.localizedDescription as Any)
                return
            }
            print("signed in")
            self.isAuthenticated = true
        }
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
