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
    
    func isOutOfMoney() -> Bool {
        guard let lastBet = moveHistory.last else { return stack <= 0 }
        return (stack + lastBet.amount) <= 0
    }
    
    func lastBet(round: Int) -> Double {
        guard let lastAction = moveHistory.last else { return 0 }
        if lastAction.round != round { return 0 }
        
        return lastAction.amount
    }
    
    func lastMove() -> Action {
        guard let lastAction = moveHistory.last else { return .none }
        return lastAction.action
    }
    
    func lastMoveForRound(round: Int) -> Action {
        guard let lastAction = moveHistory.last else { return .none }
        if lastAction.round != round { return .none }
        
        return lastAction.action
    }

    
    /// Raises the stack to the given amount
    /// - Parameters:
    ///   - amount: amount to raise too
    ///   - round: current round (preflop, flop, turn, river)
    /// - Returns: Additonal amount needed to raise
    func raise(amount: Double, round: Int) -> Double {
        var amountToBet = amount

        // Subtract any existing bet in this round to find the additional amount needed
        if let lastAction = moveHistory.last, lastAction.round == round {
            amountToBet -= lastAction.amount
        }

        // Deduct from stack and record the raise
        stack -= amountToBet
        recordAction(.raise, amount: amount, round: round)
        return amountToBet
    }
    
    func call(amount: Double = 0, round: Int) -> Double {
        var amountNeededToCall = amount
        
        if let lastAction = moveHistory.last, lastAction.round == round {
            amountNeededToCall -= lastAction.amount
        }
        
        stack -= amountNeededToCall
        recordAction(.call, amount: amount, round: round)
        return amountNeededToCall
    }
    
    func fold(round: Int) {
        recordAction(.fold, amount: 0.0, round: round)
    }
    
    func check(round: Int) {
        recordAction(.check, round: round)
    }
    
    
    private func recordAction(_ action: Action, amount: Double = 0, round: Int) {
        let record = ActionRecord(action: action, amount: amount, round: round)
        moveHistory.append(record)
    }
    
    // Used to send to the backend api
    func getHand() -> String {
        let rankOrder: [String: Int] = [
            "A": 14, "K": 13, "Q": 12, "J": 11,
            "T": 10, "9": 9, "8": 8, "7": 7,
            "6": 6, "5": 5, "4": 4, "3": 3, "2": 2
        ]
        
        let card1 = hand[0].rank
        let card2 = hand[1].rank
        let suit1 = hand[0].suit
        let suit2 = hand[1].suit
        
        let card1RankValue = rankOrder[card1] ?? 0
        let card2RankValue = rankOrder[card2] ?? 0
        
        let highRank: String
        let lowRank: String
        
        if card1RankValue >= card2RankValue {
            highRank = card1
            lowRank = card2
        } else {
            highRank = card2
            lowRank = card1
        }
        
        if card1 == card2 {
            return "\(highRank)\(lowRank)"
        }
        
        if suit1 == suit2 {
            return "\(highRank)\(lowRank)s"
        } else {
            return "\(highRank)\(lowRank)o"
        }
    }
}
