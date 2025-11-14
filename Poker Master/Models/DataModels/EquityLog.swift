//
//  EquityLog.swift
//  Poker Master
//
//  Created by Ned Whittleton on 11/13/25.
//

import SwiftData
import Foundation

// enum for villain type
enum VillainType: String, Codable, CaseIterable {
    case range
    case hand
}

// enum for street type
enum Street: String, Codable, CaseIterable {
    case preflop
    case flop
    case turn
    case river
}

@Model
class EquityLog {
    @Attribute(.unique) var id: UUID
    
    var street: Street
    var villainType: VillainType
    var hand: String
    
    
    var equity: Int
    
    var xpEarned: Int
    var isCorrect: Bool
    
    var date: Date = Date()
    
    var game: Game?
    

    init (street: Street, villainType: VillainType, hand: String, equity: Int, xpEarned: Int, isCorrect: Bool, game: Game) {
        self.id = UUID()
        self.street = street
        self.villainType = villainType
        self.hand = hand
        self.equity = equity
        self.xpEarned = xpEarned
        self.isCorrect = isCorrect
        self.game = game
    }
}
