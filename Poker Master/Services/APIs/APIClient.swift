//
//  APIClient.swift
//  Poker Master
//
//  Created by Ned Whittleton on 1/9/26.
//
import Foundation

enum APIEnvironment {
    case local
    case staging
    case production

    var baseURL: String {
        switch self {
        case .local:
            return "http://127.0.0.1:8000/api/v1"
        case .staging:
            return "https://pokerapi-887971801517.us-east4.run.app/api/v1"
        case .production:
            return "https://pokerapi-887971801517.us-east4.run.app/api/v1"
        }
    }
}

final class APIClient {
    private let authManager: AuthManager
    private let environment: APIEnvironment
    private let session: URLSession
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    init(authManager: AuthManager, session: URLSession = .shared) {
        self.authManager = authManager
        self.environment = APIConfig.environment
        self.session = session
    }
    
    func makeRequest(
        path: String,
        method: String = "POST",
        body: Encodable? = nil
    ) async throws -> URLRequest {
        
        let token = try await authManager.getIDToken(forceRefresh: false)
        
        guard let url = URL(string: environment.baseURL + path) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        if let body {
            request.httpBody = try encoder.encode(body)
        }
        
        return request
    }
    
    func send<T: Decodable>(_ request: URLRequest, allowRetry: Bool = true) async throws -> T {
        let (data, response) = try await session.data(for: request)
        
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        switch http.statusCode {
        case 200...299:
            return try decoder.decode(T.self, from: data)
            
        case 401:
            Log.network.warning("Unauthorized request")
            if allowRetry {
                Log.network.warning("Retrying with refreshed token")
                return try await retryWithRefreshedToken(request)
            } else {
                Log.network.error("User not authenticated")
                throw TokenError.userNotAuthenticated
            }
            
        default:
            Log.network.error("Request failed with status code: \(http.statusCode) On path: \(request.url?.absoluteString ?? "Unknown")")
            throw URLError(.badServerResponse)
        }
    }
    
    private func retryWithRefreshedToken<T: Decodable>(_ request: URLRequest) async throws -> T {
        let newToken = try await authManager.getIDToken(forceRefresh: true)
        var retryRequest = request
        retryRequest.setValue("Bearer \(newToken)", forHTTPHeaderField: "Authorization")
        return try await send(retryRequest, allowRetry: false)
    }
}
