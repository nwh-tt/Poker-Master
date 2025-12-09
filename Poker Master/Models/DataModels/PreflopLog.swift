//
//  HandLog.swift
//  Poker Master
//
//  Created by Ned Whittleton on 12/8/25.
//

import Foundation
import SwiftData

@Model
class PreflopLog {
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

enum RaiseType: String, Codable, CaseIterable {
    case open
    case vsRaise
    case threeBet = "3bet"
    case fourBet = "4bet"
    case fiveBet = "5bet"
}
