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
    private let client: APIClient
    
    init(authManager: AuthManager) {
        self.client = APIClient(authManager: authManager)
    }
    
    func fetchAIPlayers(tableSize: String) async throws -> [FetchPlayerResponse] {
        
        let request = try await client.makeRequest(path: "/ai/players?table_size\(tableSize)", method: "GET")
        
        return try await client.send(request)
    }
    
    // Pot odds is amount in / pot
    func fetchAiDecision(aiName: String, aiHole: [String], board: [String], potOdds: Double, opponentCount: Int, possibleMoves: [String]) async throws -> String {
        
        let body = FetchAiDecisionRequest(aiName: aiName, aiHole: aiHole, board: board, potOdds: potOdds, numOpponents: opponentCount, possibleMoves: possibleMoves)
        
        let request = try await client.makeRequest(path: "/ai/decision", method: "POST", body: body)
        
        return try await client.send(request)
    }
    
    
    func processWinners(playersLeft: [AIPlayer], board: [String]) async throws -> DetermineWinnerResponse {
        
        let playerDetails = playersLeft.map { player in
            PlayersLeftDetails(name: player.name, hand: player.hand.map { $0.toString() })
        }
        let body = DetermineWinnerRequest(players: playerDetails, board: board)
        
        let request = try await client.makeRequest(path: "/ai/determine-winner", method: "POST", body: body)
        return try await client.send(request)
    }
}
