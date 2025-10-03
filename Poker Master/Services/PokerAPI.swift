import Foundation

struct EquityRequest: Codable {
    let hero_hole: [String]
    let villain_range: [String]
    let board: [String]
}

struct EquityRequestHand: Codable {
    let hero_hole: [String]
    let villain_hole: [String]
    let board: [String]
}

struct EquityResponse: Codable {
    let low_equity: Int
    let high_equity: Int
}

class EquityAPI {
    let authManager: AuthManager
    let apiPrefix = "https://pokermasterbackend-production.up.railway.app"
    //let apiPrefix = "http://127.0.0.1:8000"
    
    init(authManager: AuthManager) {
        self.authManager = authManager
    }
    
    // Make sure this function is marked 'async' and 'throws'.
    func fetchEquityRange(heroHole: [String], villainRange: [String], board: [String] = []) async throws -> EquityResponse {
        
        // 1. Await the token safely (no longer need the separate guard/do block)
        // Assuming authManager is a stored property in this class
        let authToken = try await authManager.getIDToken(forceRefresh: false) // Use try await

        // Build the request after we have a valid token
        guard let url = URL(string: "\(apiPrefix)/api/equity/from-range") else {
            // Use throws instead of calling completion(nil)
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        // 2. Attach the secure token
        request.addValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")

        let body = EquityRequest(hero_hole: heroHole, villain_range: villainRange, board: board)

        // Error handling for encoding is now automatic via try/catch in the caller
        request.httpBody = try JSONEncoder().encode(body)

        // 3. Use async URLSession API
        let (data, response) = try await URLSession.shared.data(for: request)

        // 4. Check HTTP status code
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            
            if statusCode == 401 {
                // Throw a specific authentication error for your AuthManager to handle
                throw TokenError.userNotAuthenticated
            }
            
            // Throw a generic error for other server issues
            throw URLError(.badServerResponse)
        }

        // 5. Decode and return (throws on decode failure)
        return try JSONDecoder().decode(EquityResponse.self, from: data)
    }
    
    func fetchEquityVsHand(heroHole: [String], villainHole: [String], board: [String] = [], completion: @escaping (EquityResponse?) -> Void) {
        
        // Change port if your FastAPI runs on something else
        guard let url = URL(string: "\(apiPrefix)/api/equity/from-hand") else {
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = EquityRequestHand(hero_hole: heroHole, villain_hole: villainHole, board: board)
        
        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            print("Error encoding body: \(error)")
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Request error: \(String(describing: error))")
                completion(nil)
                return
            }

            do {
                let equityResponse = try JSONDecoder().decode(EquityResponse.self, from: data)
                completion(equityResponse)
            } catch {
                print("Decoding error: \(error)")
                completion(nil)
            }
        }.resume()
    }

}
