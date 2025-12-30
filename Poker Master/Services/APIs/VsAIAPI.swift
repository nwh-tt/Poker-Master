//
//  VsAIAPI.swift
//  Poker Master
//
//  Created by Ned Whittleton on 12/5/25.
//
import Foundation

struct FetchPlayerResponse: Codable {
    let name: String
    let full_name: String
}

struct FetchAiDecisionRequest: Codable {
    let aiName: String
    let aiHole: [String]
    let board: [String]
    let potOdds: Double
    let numOpponents: Int
    let possibleMoves: [String]
}

struct PlayersLeftDetails: Codable {
    let name: String
    let hand: [String]
}

struct DetermineWinnerRequest: Codable {
    let players: [PlayersLeftDetails]
    let board: [String]
}

struct PlayerDetails: Codable {
    let name: String
    let hand: [String]
    let score: Int
    let hand_name: String
}

struct DetermineWinnerResponse: Codable {
    let winners: [String]
    let player_details: [PlayerDetails]
}

class VsAIAPI {
    let authManager: AuthManager
    let apiPrefix = APIConfig.baseURL
    
    init(authManager: AuthManager) {
        self.authManager = authManager
    }
    
    func fetchAIPlayers(tableSize: String) async throws -> [FetchPlayerResponse] {
        
        guard let url = URL(string: "\(apiPrefix)/ai/players?table_size=\(tableSize)") else {
            throw URLError(.badURL)
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }

            let decoded = try JSONDecoder().decode([FetchPlayerResponse].self, from: data)
            return decoded

        } catch let error {
            // Throw error here
            throw error
        }
    }
    
    // Pot odds is amount in / pot
    func fetchAiDecision(aiName: String, aiHole: [String], board: [String], potOdds: Double, opponentCount: Int, possibleMoves: [String]) async throws -> String {
        guard let url = URL(string: "\(apiPrefix)/ai/decision") else {
            throw URLError(.badURL)
        }
        
        let requestBody = FetchAiDecisionRequest(aiName: aiName, aiHole: aiHole, board: board, potOdds: potOdds, numOpponents: opponentCount, possibleMoves: possibleMoves)
        
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(requestBody)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw URLError(.badServerResponse)
            }
            
            return try JSONDecoder().decode(String.self, from: data)
        } catch let error {
            // Throw error here
            throw error
        }
    }
    
    
    func processWinners(playersLeft: [AIPlayer], board: [String]) async throws -> DetermineWinnerResponse {
        guard let url = URL(string: "\(apiPrefix)/ai/determine-winner") else {
            throw URLError(.badURL)
        }
        
        let playerDetails = playersLeft.map { player in
            PlayersLeftDetails(name: player.name, hand: player.hand.map { $0.toString() })
        }
        let requestBody = DetermineWinnerRequest(players: playerDetails, board: board)
        
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(requestBody)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw URLError(.badServerResponse)
            }
            
            let decoded = try JSONDecoder().decode(DetermineWinnerResponse.self, from: data)
            return decoded
        } catch let error {
            // Throw error here
            throw error
        }
    }
}
