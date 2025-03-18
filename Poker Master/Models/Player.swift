//
//  Player.swift
//  Poker Master
//
//  Created by Ned Whittleton on 4/18/24.
//

import Foundation

// make an enum for last move
enum LastMove: String {
    case call = "Call"
    case raise = "Raise"
    case fold = "Fold"
    case none = "None"
}

class Player {
    var position: String
    var stack: Double
    var hand: [Card] = []
    var lastMove: LastMove = LastMove.none
    var betAmount: Double = 0.0
    
    
    init(position: String, stack: Double) {
        self.position = position
        self.stack = stack
    }
    
    func raise(amount: Double) {
        bet(amount: amount)
        lastMove = LastMove.raise
    }
    
    func call(amount: Double) {
        bet(amount: amount)
        lastMove = LastMove.call
    }
    
    func bet(amount: Double) {
        stack -= amount
        betAmount += amount
    }
    
    func deal(card: Card) {
        hand.append(card)
    }
    
    func toString() -> String {
        return "Position: \(position), Stack: \(stack), Hand: \(hand[0].toString()), \(hand[1].toString())"
    }
    
    // should return the hand like this "A9s" if same suit or "A9o" if not same suit bigger card should always be first
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

