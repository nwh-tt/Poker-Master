//
//  AIPlayer.swift
//  Poker Master
//
//  Created by Ned Whittleton on 10/11/25.
//
import Observation
import Foundation

struct ActionRecord {
    let action: Action
    let amount: Double
    let game: Int // Iterates up through games (used for tying history to a game)
    let round: Int // Preflop = 0, Flop = 1, Turn = 2, River = 3
}

@Observable
class AIPlayer: Identifiable {
    let id = UUID()
    var name: String
    var fullName: String
    var position: String
    var stack: Double
    var hand: [Card]
    var moveHistory: [ActionRecord]
    var isUser: Bool
    
    init(name: String, fullName: String, position: String, stack: Double = 100, hand: [Card] = [], moveHistory: [ActionRecord] = [], isUser: Bool = false) {
        self.name = name
        self.fullName = fullName
        self.position = position
        self.stack = stack
        self.hand = hand
        self.moveHistory = moveHistory
        self.isUser = isUser
    }
    
    func isOutOfMoney(game: Int) -> Bool {
        guard let lastBet = moveHistory.last else { return stack <= 0 }
        if lastBet.game != game { return stack <= 0 }
        return (stack + lastBet.amount) <= 0
    }
    
    func lastBet(game: Int, round: Int) -> Double {
        guard let lastAction = moveHistory.last else { return 0 }
        if lastAction.game != game { return 0 }
        if lastAction.round != round { return 0 }
        
        return lastAction.amount
    }
    
    func lastMove(game: Int) -> Action {
        guard let lastAction = moveHistory.last else { return .none }
        if lastAction.game != game { return .none }
        
        return lastAction.action
    }
    
    func lastMoveForRound(game: Int, round: Int) -> Action {
        guard let lastAction = moveHistory.last else { return .none }
        if lastAction.round != round { return .none }
        if lastAction.game != game { return .none }
        
        return lastAction.action
    }

    
    /// Raises the stack to the given amount
    /// - Parameters:
    ///   - amount: amount to raise too
    ///   - round: current round (preflop, flop, turn, river)
    /// - Returns: Additonal amount needed to raise
    func raise(amount: Double, game: Int, round: Int) -> Double {
        var amountToBet = amount

        // Subtract any existing bet in this round to find the additional amount needed
        if let lastAction = moveHistory.last, lastAction.round == round {
            amountToBet -= lastAction.amount
        }

        // Deduct from stack and record the raise
        stack -= amountToBet
        recordAction(.raise, amount: amount, game: game, round: round)
        return amountToBet
    }
    
    func call(amount: Double = 0, game: Int, round: Int) -> Double {
        var amountNeededToCall = amount
        
        if let lastAction = moveHistory.last, lastAction.round == round {
            amountNeededToCall -= lastAction.amount
        }
        
        stack -= amountNeededToCall
        recordAction(.call, amount: amount, game: game, round: round)
        return amountNeededToCall
    }
    
    func fold(game: Int, round: Int) {
        recordAction(.fold, amount: 0.0, game: game, round: round)
    }
    
    func check(game: Int, round: Int) {
        recordAction(.check, game: game, round: round)
    }
    
    
    private func recordAction(_ action: Action, amount: Double = 0, game: Int, round: Int) {
        let record = ActionRecord(action: action, amount: amount, game: game, round: round)
        moveHistory.append(record)
    }
}
