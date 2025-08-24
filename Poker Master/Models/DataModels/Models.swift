//
//  Models.swift
//  Poker Master
//
//  Created by Ned Whittleton on 8/23/25.
//

import SwiftData
import Foundation

// MARK: - Challenge Definition
@Model
class Challenges {
    @Attribute(.unique) var id: UUID
    var title: String
    var desc: String
    var icon: String
    var goals: [Int]   // Example: [10, 50, 200, 500]
    
    init(title: String, description: String, icon: String, goals: [Int]) {
        self.id = UUID()
        self.title = title
        self.desc = description
        self.icon = icon
        self.goals = goals
    }
    
    //
}

// MARK: - Game
@Model
class Game {
    @Attribute(.unique) var id: UUID
    var date: Date
    var totalHands: Int
    
    var duration: Double

    // Relationship: 1 Game → Many Hands
    var hands: [HandLog] = []

    init(date: Date = Date(), totalHands: Int = 0, duration: Double = 0.0) {
        self.id = UUID()
        self.date = date
        self.totalHands = totalHands
        self.duration = duration
    }
}

// MARK: - Hand Log
@Model
class HandLog {
    @Attribute(.unique) var id: UUID
    
    var typeOfHand: String // "preFlop", "flop", "turn", "river"
    var position: String
    var hand: String
    var pair: Bool
    
    
    var action: String // "raise", "call", "fold"
    var raiseType: String // open, vsRaise, "3bet, 4bet", "5bet"
    var betAmount: Double
    var pot: Double
    
    var xpEarned: Int
    var isCorrect: Bool
    
    var date: Date
    
    var game: Game?
    
    init(typeOfHand: String, position: String, hand: String, pair: Bool, action: String = "open", raiseType: String, betAmount: Double, pot: Double = 0, xpEarned: Int, isCorrect: Bool, date: Date = Date(), game: Game) {
        self.id = UUID()
        self.typeOfHand = typeOfHand
        self.position = position
        self.hand = hand
        self.pair = pair
        self.action = action
        self.raiseType = raiseType
        self.betAmount = betAmount
        self.pot = pot
        self.xpEarned = xpEarned
        self.isCorrect = isCorrect
        self.date = date
        self.game = game
    }
}
