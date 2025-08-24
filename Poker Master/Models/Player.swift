//
//  Player.swift
//  Poker Master
//
//  Created by Ned Whittleton on 4/18/24.
//

import Foundation

// make an enum for last move
enum Move: String {
    case call = "Call"
    case raise = "Raise"
    case fold = "Fold"
    case none = "None"
}

class Player {
    var position: String
    var stack: Double
    var hand: [Card]
    var lastMove: Move
    var currentBetAmount: Double
    var isReRaise: Bool = false
    
    
    init(position: String, stack: Double, betAmount: Double = 0.0, hand: [Card] = [], lastMove: Move = Move.none) {
        self.position = position
        self.stack = stack
        self.currentBetAmount = betAmount
        self.hand = hand
        self.lastMove = lastMove
    }
    
    // amount is the amount to raise to (need to account for the current bet amount)
    func raise(amountRaisingTo: Double) -> Double {
        if (lastMove == Move.raise) {
            isReRaise = true // variable used for ui display
        }
            
        let difference = amountRaisingTo - currentBetAmount
        bet(amount: difference)
        lastMove = Move.raise
        return difference
    }
    
    func call(amountCallingTo: Double) -> Double {
        let difference = amountCallingTo - currentBetAmount
        bet(amount: difference)
        lastMove = Move.call
        return difference
    }
    
    func bet(amount: Double) {
        stack -= amount
        currentBetAmount += amount
    }
    
    func deal(card: Card) {
        hand.append(card)
    }
    
    func toString() -> String {
        if hand.isEmpty {
            return "Position: \(position), Stack: \(stack), Last Bet: \(currentBetAmount)"
        }
        return "Position: \(position), Stack: \(stack), Last Bet: \(currentBetAmount), Hand: \(hand[0].toString()), \(hand[1].toString())"
    }
    
    func setHand(hand: String) {
        // check if hand is empty
        guard !hand.isEmpty else {
            print("Empty hand string")
            return
        }
        let ranks = Array(hand)
        let rank1 = String(ranks[0])
        let rank2 = String(ranks[1])
        
        let suitedness = ranks.count == 3 ? String(ranks[2]) : "o"

        let suits = ["heart", "diamond", "club", "spade"]

        var suit1 = suits.randomElement()!
        var suit2 = suits.randomElement()!

        if suitedness == "s" {
            suit2 = suit1 // same suit
        } else if suitedness == "o" {
            // ensure different suits
            while suit2 == suit1 {
                suit2 = suits.randomElement()!
            }
        }

        let card1 = Card(suit: suit1, rank: rank1)
        let card2 = Card(suit: suit2, rank: rank2)
    
        self.hand = [card1, card2]
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
    
    func handIsPair() -> Bool {
        let rankOrder: [String: Int] = [
                "A": 14, "K": 13, "Q": 12, "J": 11,
                "T": 10, "9": 9, "8": 8, "7": 7,
                "6": 6, "5": 5, "4": 4, "3": 3, "2": 2
            ]
        
        let card1 = hand[0].rank
        let card2 = hand[1].rank
        let card1RankValue = rankOrder[card1] ?? 0
        let card2RankValue = rankOrder[card2] ?? 0
        return card1RankValue == card2RankValue
    }
}

