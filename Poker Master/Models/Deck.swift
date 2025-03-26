//
//  Deck.swift
//  Poker Master
//
//  Created by Ned Whittleton on 4/22/24.
//

import Foundation


enum Suit: String, CaseIterable {
    case hearts = "heart"
    case diamonds = "diamond"
    case clubs = "club"
    case spades = "spade"
}

enum Rank: String, CaseIterable {
    case ace = "A"
    case two = "2"
    case three = "3"
    case four = "4"
    case five = "5"
    case six = "6"
    case seven = "7"
    case eight = "8"
    case nine = "9"
    case ten = "10"
    case jack = "J"
    case queen = "Q"
    case king = "K"
}

class Deck {
    var cards: [Card] = []
    
    
    init() {
        createDeck()
    }
    
    private func createDeck() {
        cards = []
        for suit in Suit.allCases {
            for rank in Rank.allCases {
                cards.append(Card(suit: suit.rawValue, rank: rank.rawValue))
            }
        }
        cards.shuffle()
    }
    
    func dealCard() -> Card {
        return cards.removeFirst()
    }
    
    func resetDeck() {
        createDeck()
    }
    
    func toString() -> String {
        var deckString = ""
        for card in cards {
            deckString += card.toString() + "\n"
        }
        return deckString
    }
}
