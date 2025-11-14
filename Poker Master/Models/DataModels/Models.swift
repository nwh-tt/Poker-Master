//
//  Models.swift
//  Poker Master
//
//  Created by Ned Whittleton on 8/23/25.
//

import SwiftData
import SwiftUI
import Foundation



// MARK: - Profile Definition
@Model
class Profile {
    @Attribute(.unique) var id: UUID
    var username: String
    var email: String? = nil // Not required
    var avatar: String? = nil // image name or URL
    
    var xp: Int = 0 // starts at 0
    var totalXP: Int = 0
    
    var level: Int = 1 // starts at 1
    var leveledUP: Bool = false
    
    var xpNeededForNextLevel: Int {
        Int(10 * log(Double(level) + 1)) // log curve
    }
    
    init(username: String) {
        self.id = UUID()
        self.username = username
    }
    
    func addXP(amount: Int) {
        xp += amount
        totalXP += amount
        while xp >= xpNeededForNextLevel {
            xp -= xpNeededForNextLevel
            level += 1
            leveledUP = true
        }
    }
}

// MARK: - Challenge Definition
@Model
class Challenges {
    @Attribute(.unique) var id: UUID
    var title: String
    var desc: String
    var icon: String
    var goals: [Int]   // Example: [10, 50, 200, 500]
    var claimed: [Bool]
    
    init(title: String, description: String, icon: String, goals: [Int]) {
        self.id = UUID()
        self.title = title
        self.desc = description
        self.icon = icon
        self.goals = goals
        self.claimed = Array(repeating: false, count: goals.count)
    }
    
    func markTierClaimed(_ tier: ChallengeTier) {
        let idx = tier.index
        if idx < claimed.count {
            var newClaimed = claimed
            newClaimed[idx] = true
            claimed = newClaimed  // <- triggers SwiftUI update
        }
    }

    func isTierClaimed(_ tier: ChallengeTier) -> Bool {
        let idx = tier.index
        return idx < claimed.count ? claimed[idx] : false
    }
}

enum ChallengeTier: String, CaseIterable {
    case bronze, silver, gold, platinum, diamond, legend
        
        var color: Color {
            switch self {
            case .bronze: return Color(red: 205/255, green: 127/255, blue: 50/255)
            case .silver: return Color(red: 192/255, green: 192/255, blue: 192/255)
            case .gold: return Color(red: 255/255, green: 215/255, blue: 0)
            case .platinum: return Color(red: 217/255, green: 217/255, blue: 217/255)
            case .diamond: return Color(red: 154/255, green: 197/255, blue:219/255)
            case .legend: return Color(red: 1.0, green: 0.0, blue: 1.0)
            }
        }
    
    var index: Int {
            Self.allCases.firstIndex(of: self)!
        }
}

enum GameType: String, Codable {
    case preFlop
    case aiVsHuman
    case equityDrill
}

// MARK: - Game
@Model
class Game {
    @Attribute(.unique) var id: UUID
    var date: Date
    
    var gameType: GameType
    var totalHands: Int
    var duration: Double

    // Relationship: 1 Game → Many Hands
    var preflopHands: [HandLog] = []
    var equityHands: [EquityLog] = []
    var aiGameHands: [AIGameLog] = []
    

    init(date: Date = Date(), gameType: GameType, totalHands: Int = 0, duration: Double = 0.0) {
        self.id = UUID()
        self.gameType = gameType
        self.date = date
        self.totalHands = totalHands
        self.duration = duration
    }
}

// MARK: - Hand Log
@Model
class HandLog {
    @Attribute(.unique) var id: UUID
    
    var position: Position
    var hand: String
    var pair: Bool
    
    
    var action: Action // "raise", "call", "fold"
    var raiseType: RaiseType // open, vsRaise, "3bet, 4bet", "5bet"
    var betAmount: Double
    var pot: Double
    
    var xpEarned: Int
    var isCorrect: Bool
    
    var date: Date
    
    var game: Game?
    
    init(position: Position, hand: String, pair: Bool, action: Action, raiseType: RaiseType, betAmount: Double, pot: Double = 0, xpEarned: Int, isCorrect: Bool, date: Date = Date(), game: Game) {
        self.id = UUID()
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

enum Position: String, Codable, CaseIterable {
    case utg, utg1, utg2, mp, mp1, mp2, co, btn, sb, bb
}

enum Action: String, Codable, CaseIterable {
    case fold, call, raise, check, none
}

enum RaiseType: String, Codable, CaseIterable {
    case open
    case vsRaise
    case threeBet = "3bet"
    case fourBet = "4bet"
    case fiveBet = "5bet"
}
