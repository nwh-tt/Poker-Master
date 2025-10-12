//
//  AIPlayer.swift
//  Poker Master
//
//  Created by Ned Whittleton on 10/11/25.
//
import Observation

struct ActionRecord {
    let action: Action
    let amount: Double
    let round: Int // Preflop = 0, Flop = 1, Turn = 2, River = 3
}

@Observable
class AIPlayer {
    var name: String
    var position: String
    var stack: Double
    var hand: [Card]
    var moveHistory: [ActionRecord]
    
    init(name: String, position: String, stack: Double = 100, hand: [Card] = [], moveHistory: [ActionRecord] = []) {
        self.name = name
        self.position = position
        self.stack = stack
        self.hand = hand
        self.moveHistory = moveHistory
    }
    
    func isOutOfMoney() -> Bool {
        return stack <= 0
    }
    
    func lastBet() -> Double {
        guard let lastAction = moveHistory.last else { return 0 }
        return lastAction.amount
    }
    
    func lastMove() -> Action {
        guard let lastAction = moveHistory.last else { return .none }
        return lastAction.action
    }
    
    func isReRaise() -> Bool {
        // Need at least 2 moves to check consecutive raises
        guard moveHistory.count >= 2 else { return false }

        let last = moveHistory[moveHistory.count - 1]
        let secondLast = moveHistory[moveHistory.count - 2]

        return last.action == .raise && secondLast.action == .raise
    }

    func raise(amount: Double, round: Int) -> Double {
        var amountToBet = amount
        guard let lastAction = moveHistory.last else {
            stack -= amountToBet
            recordAction(.raise, amount: amount, round: round)
            return amountToBet
        }
        if lastAction.round == round {
            amountToBet -= lastAction.amount
        }
        
        stack -= amountToBet
        recordAction(.raise, amount: amount, round: round)
        return amountToBet
    }
    
    func call(amount: Double = 0, round: Int) -> Double {
        var amountNeededToCall = amount
        guard let lastAction = moveHistory.last else {
            stack -= amountNeededToCall
            recordAction(.call, amount: amount, round: round)
            return amountNeededToCall
        }
        if lastAction.round == round {
            amountNeededToCall -= lastAction.amount
        }
        
        stack -= amountNeededToCall
        recordAction(.call, amount: amount, round: round)
        return amountNeededToCall
    }
    
    func fold(round: Int) {
        recordAction(.fold, amount: 0.0, round: round)
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
