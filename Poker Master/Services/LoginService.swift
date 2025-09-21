//
//  LoginService.swift
//  Poker Master
//
//  Created by Ned Whittleton on 9/19/25.
//

import Foundation
import Security

final class LoginService {
    
    static let shared = LoginService() // Singleton
    
    private let accountKey = "userSessionToken"
    
    private init() {}
    
    // MARK: - Save Token
    func saveToken(_ token: String) -> Bool {
        guard let data = token.data(using: .utf8) else { return false }
        
        // Delete any existing token first
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: accountKey
        ]
        SecItemDelete(deleteQuery as CFDictionary)
        
        // Add new token
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: accountKey,
            kSecValueData as String: data
        ]
        
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    // MARK: - Get Token
    func getToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: accountKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        guard status == errSecSuccess,
              let data = dataTypeRef as? Data,
              let token = String(data: data, encoding: .utf8) else { return nil }
        
        return token
    }
    
    // MARK: - Delete Token (Logout)
    func deleteToken() -> Bool {
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: accountKey
        ]
        let status = SecItemDelete(deleteQuery as CFDictionary)
        return status == errSecSuccess
    }
    
    // MARK: - Check if Logged In
    var isLoggedIn: Bool {
        return getToken() != nil
    }
}

