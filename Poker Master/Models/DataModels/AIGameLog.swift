//
//  AIGameLog.swift
//  Poker Master
//
//  Created by Ned Whittleton on 11/13/25.
//


import SwiftData
import Foundation

@Model
class AIGameLog {
    @Attribute(.unique) var id: UUID
    
    var hand: String
    var board: [String] = []
    
    // Stat tracking for user choice
    var raises: Int = 0
    var calls: Int = 0
    var folds: Int = 0
    var allIns: Int = 0
    
    // Total bet and pot through each stage of the game (combine all total bet will get amount user is in)
    var totalBet: Double = 0
    var pot: Double = 0 // Getting pot for a won hand will get you amount won
    
    // Completion details (if this is the final hand of the overall round)
    var wonHand: Bool?
    var wasShowdown: Bool { !showdownPlayers.isEmpty }
    var showdownPlayers: [String] = []

    // Core data
    var xpEarned: Int
    var date: Date = Date()
    
    var game: Game?
    

    init (hand: String, equity: String, xpEarned: Int = 0, game: Game) {
        self.id = UUID()
        self.hand = hand
        self.xpEarned = xpEarned
        self.game = game
    }
}
