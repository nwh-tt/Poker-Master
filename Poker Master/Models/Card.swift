//
//  Card.swift
//  Poker Master
//
//  Created by Ned Whittleton on 4/22/24.
//

import Foundation

class Card {
    var suit: String
    var rank: String
    
    init(suit: String, rank: String) {
        self.suit = suit
        self.rank = rank
    }
    
    func toString() -> String {
        return "\(rank) of \(suit)"
    }
}
