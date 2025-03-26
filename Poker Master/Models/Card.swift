//
//  Card.swift
//  Poker Master
//
//  Created by Ned Whittleton on 4/22/24.
//

import Foundation

class Card: Equatable {
    var suit: String
    var rank: String
    
    init(suit: String, rank: String) {
        self.suit = suit
        self.rank = rank
    }
    
    func toString() -> String {
        return "\(rank) of \(suit)"
    }
    
    static func == (lhs: Card, rhs: Card) -> Bool {
        return lhs.rank == rhs.rank && lhs.suit == rhs.suit
    }
}
