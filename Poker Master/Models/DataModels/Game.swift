//
//  Game.swift
//  Poker Master
//
//  Created by Ned Whittleton on 12/8/25.
//

import Foundation
import SwiftData

@Model
class Game {
    @Attribute(.unique) var id: UUID
    var date: Date
    
    var gameType: GameType
    var totalHands: Int
    var duration: Double

    // Relationship: 1 Game → Many Hands
    var preflopHands: [PreflopLog] = []
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

enum GameType: String, Codable {
    case preFlop
    case aiVsHuman
    case equityDrill
}
