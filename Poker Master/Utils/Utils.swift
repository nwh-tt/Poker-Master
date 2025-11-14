//
//  Utils.swift
//  Poker Master
//
//  Created by Ned Whittleton on 11/12/25.
//
import SwiftUI

extension Double {
    func formattedString() -> String {
        if self.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", self)
        } else {
            return String(format: "%.1f", self)
        }
    }
}

extension String {
    var capitalizeFirst: String {
        guard let first = first else { return self }
        return String(first).uppercased() + dropFirst()
    }
}


extension Array where Element == Card {
    func handToString() -> String {
        let rankOrder: [String: Int] = [
            "A": 14, "K": 13, "Q": 12, "J": 11,
            "T": 10, "9": 9, "8": 8, "7": 7,
            "6": 6, "5": 5, "4": 4, "3": 3, "2": 2
        ]
        
        let card1 = self[0].rank
        let card2 = self[1].rank
        let suit1 = self[0].suit
        let suit2 = self[1].suit
        
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


// View extensions
extension View {
    func countingPlayerText(to value: Double, color: Color, offset: Int) -> some View {
        self.modifier(CountingPlayerText(value: value, textColor: color, textOffset: offset))
    }
}

extension View {
    func countingText(to value: Double) -> some View {
        self.modifier(CountingText(value: value))
    }
}
