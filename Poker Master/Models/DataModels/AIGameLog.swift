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
    var board: [String]
    
    // Round
    var street: Street
    
    // Stat tracking for user choice
    var raises: Int = 0
    var calls: Int = 0
    var folds: Int = 0
    var allIns: Int = 0
    
    // Total bet and pot through each stage of the game (combine all total bet will get amount user is in)
    var totalRaised: Double = 0
    var totalCalled: Double = 0
    var totalBet: Double = 0
    var pot: Double = 0 // Getting pot for a won hand will get you amount won
    
    // Completion details (if this is the final hand of the overall round)
    var wonHand: Bool?
    var wasShowdown: Bool { !showdownPlayers.isEmpty }
    var reachedShowdown: Bool = false
    var showdownPlayers: [String] = []

    // Core data
    var xpEarned: Int
    var date: Date = Date()
    
    var game: Game?
    

    init (hand: String, board: [String] = [], street: Street, xpEarned: Int = 0, game: Game) {
        self.id = UUID()
        self.hand = hand
        self.board = board
        self.street = street
        self.xpEarned = xpEarned
        self.game = game
    }
    
    // Function for handling what user input was
    func addBet(action: String, amount: Double) {
        if action == "raise" {
            raises += 1
            totalBet = amount
        }
        else if action == "call" {
            calls += 1
            totalBet = amount
        }
        else if action == "fold" {
            folds += 1
        }
        else if action == "allIn" {
            allIns += 1
            totalBet = amount
        }
    }
    
    func setStreet(streetNum: Int) {
        street = Street.allCases[streetNum]
    }
}

