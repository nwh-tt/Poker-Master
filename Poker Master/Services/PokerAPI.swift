//
//  PokerAPI.swift
//  Poker Master
//
//  Created by Ned Whittleton on 8/6/25.
//
import Foundation

// Define your request model
struct MultiwayPreflopEVRequest: Codable {
    let hero_hole: [String]
    let pot_size: Double
    let call_amount: Double
    let raise_amount: Double?
    let num_opponents: Int
    let fold_chance: Double?
}

// Define your response model
struct MultiwayPreflopEVResponse: Codable {
    let equity: Double
    let call_ev: Double
    let raise_ev: Double?  // optional, only if raise_amount was provided
}

func fetchMultiwayPreflopEV(requestData: MultiwayPreflopEVRequest) async throws -> MultiwayPreflopEVResponse {
    guard let url = URL(string: "http://127.0.0.1:8000/api/ev/multiway-preflop-ev") else {
        throw URLError(.badURL)
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    // Encode request data as JSON
    request.httpBody = try JSONEncoder().encode(requestData)
    
    // Perform the request
    let (data, response) = try await URLSession.shared.data(for: request)
    
    // Check for HTTP errors
    guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
        throw URLError(.badServerResponse)
    }
    
    // Decode JSON response
    let decodedResponse = try JSONDecoder().decode(MultiwayPreflopEVResponse.self, from: data)
    
    return decodedResponse
}

