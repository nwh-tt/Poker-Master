import Foundation

struct EquityRequest: Codable {
    let hero_hole: [String]
    let villain_range: [String]
    let board: [String]
    let isPaid: Bool
}

struct EquityRequestHand: Codable {
    let hero_hole: [String]
    let villain_hole: [String]
    let board: [String]
    let isPaid: Bool
}

struct EquityResponse: Codable {
    let low_equity: Int
    let high_equity: Int
}

class EquityAPI {
    private let client: APIClient
    
    init(authManager: AuthManager) {
        self.client = APIClient(authManager: authManager)
    }
    
    // Make sure this function is marked 'async' and 'throws'.
    func fetchEquityRange(heroHole: [String], villainRange: [String], board: [String] = [], isPaid: Bool) async throws -> EquityResponse {
        
        // 1. Await the token safely (no longer need the separate guard/do block)
        // Assuming authManager is a stored property in this class
        
        let body = EquityRequest(hero_hole: heroHole, villain_range: villainRange, board: board, isPaid: isPaid)

        let request = try await client.makeRequest(
            path: "/equity/from-range",
            method: "POST",
            body: body
        )

        // 3. Use async URLSession API
        return try await client.send(request)
    }
    
    func fetchEquityHand(heroHole: [String], villainHole: [String], board: [String] = [], isPaid: Bool) async throws -> EquityResponse {
        let body = EquityRequestHand(hero_hole: heroHole, villain_hole: villainHole, board: board, isPaid: isPaid)

        // Error handling for encoding is now automatic via try/catch in the caller
        let requestBody = try await client.makeRequest(path: "/equity/from-hand", method: "POST", body: body)

        return try await client.send(requestBody)
    }
    
    struct WinnerRequestPlayerDetails: Codable {
        let name: String
        let hand: [String]
    }

    struct DetermineWinnerRequest: Codable {
        let players: [WinnerRequestPlayerDetails]
        let board: [String]
    }

    struct DetermineWinnerResponse: Codable {
        struct Result: Codable {
            let name: String
            let hand: [String]
            let score: Int
            let hand_name: String
        }

        let winners: [String]
        let results: [Result]
    }
    

}
