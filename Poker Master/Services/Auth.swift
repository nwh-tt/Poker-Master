import Foundation
import AuthenticationServices
import FirebaseAuth
import CryptoKit
import RevenueCat
import Combine

protocol AuthUser {
    var uid: String { get }
    var email: String? { get }
}

protocol AuthServiceProtocol {
    var currentUser: User? { get }
    var isAuthenticated: Bool { get }
    func addStateDidChangeListener(_ listener: @escaping (User?) -> Void)
    func signIn(email: String, password: String, completion: @escaping (Error?) -> Void)
    func signUp(email: String, password: String, completion: @escaping (Error?) -> Void)
    func signOut() throws
    func getIDToken(forceRefresh: Bool) async throws -> String
}

class FirebaseAuthService: AuthServiceProtocol {
    var currentUser: User? { Auth.auth().currentUser }
    var isAuthenticated: Bool { Auth.auth().currentUser != nil }

    private var listeners: [(User?) -> Void] = []

    init() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.listeners.forEach { $0(user) }
        }
    }

    func addStateDidChangeListener(_ listener: @escaping (User?) -> Void) {
        listeners.append(listener)
    }

    func signIn(email: String, password: String, completion: @escaping (Error?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { _, error in
            completion(error)
        }
    }

    func signUp(email: String, password: String, completion: @escaping (Error?) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { _, error in
            completion(error)
        }
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }

    func getIDToken(forceRefresh: Bool = false) async throws -> String {
        guard let user = Auth.auth().currentUser else { throw TokenError.userNotAuthenticated }
        return try await user.getIDTokenResult(forcingRefresh: forceRefresh).token
    }
}

class AuthManager: ObservableObject {
    @Published var user: User? // The current authenticated user
    @Published var isAuthenticated: Bool = false
    
    // States to handle the UI
    @Published var errorMessage: String? = nil
    @Published var isLoading: Bool = false
    
    private var currentNonce: String?
    private let authService: AuthServiceProtocol

    init(authService: AuthServiceProtocol = FirebaseAuthService()) {
        self.authService = authService
        setupListener()
    }
    
    private func setupListener() {
        authService.addStateDidChangeListener { [weak self] user in
            guard let self = self else { return }
            self.user = user
            self.isAuthenticated = user != nil
            
            if let user = user {
                Purchases.shared.logIn(user.uid) { _, created, error in
                    if let error = error {
                        print("❌ Failed to log in to RevenueCat: \(error.localizedDescription)")
                    } else {
                        print("✅ RevenueCat login successful. New user? \(created)")
                    }
                }
            } else {
                Purchases.shared.logOut { _, error in
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
        try await authService.getIDToken(forceRefresh: forceRefresh)
    }

    // MARK: - Sign In
    func signIn(email: String, password: String) {
        errorMessage = nil // Clear any previous errors
        
        authService.signIn(email: email, password: password) { [weak self] error in
            DispatchQueue.main.async {
                self?.isAuthenticated = self?.authService.isAuthenticated ?? false
                self?.errorMessage = error?.localizedDescription
            }
        }
    }
    
    
    // MARK: - Sign Up (User Creation)
    func signUp(email: String, password: String) {
        errorMessage = nil
        isLoading = true
        authService.signUp(email: email, password: password) { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false
                self?.isAuthenticated = self?.authService.isAuthenticated ?? false
                self?.errorMessage = error?.localizedDescription
            }
        }
    }
       
       // MARK: - Sign Out
    func signOut() {
        do { try authService.signOut() }
        catch { errorMessage = error.localizedDescription }
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
