//
//  Challenge.swift
//  Poker Master
//
//  Created by Ned Whittleton on 12/8/25.
//

import Foundation
import SwiftData
import SwiftUI

@Model
class Challenges {
    @Attribute(.unique) var id: UUID
    var title: String
    var desc: String
    var icon: String
    var goals: [Int]   // Example: [10, 50, 200, 500]
    var claimed: [Bool]
    
    init(title: String, description: String, icon: String, goals: [Int]) {
        self.id = UUID()
        self.title = title
        self.desc = description
        self.icon = icon
        self.goals = goals
        self.claimed = Array(repeating: false, count: goals.count)
    }
    
    func markTierClaimed(_ tier: ChallengeTier) {
        let idx = tier.index
        if idx < claimed.count {
            var newClaimed = claimed
            newClaimed[idx] = true
            claimed = newClaimed  // <- triggers SwiftUI update
        }
    }

    func isTierClaimed(_ tier: ChallengeTier) -> Bool {
        let idx = tier.index
        return idx < claimed.count ? claimed[idx] : false
    }
}

enum ChallengeTier: String, CaseIterable {
    case bronze, silver, gold, platinum, diamond, legend
        
        var color: Color {
            switch self {
            case .bronze: return Color(red: 205/255, green: 127/255, blue: 50/255)
            case .silver: return Color(red: 192/255, green: 192/255, blue: 192/255)
            case .gold: return Color(red: 255/255, green: 215/255, blue: 0)
            case .platinum: return Color(red: 217/255, green: 217/255, blue: 217/255)
            case .diamond: return Color(red: 154/255, green: 197/255, blue:219/255)
            case .legend: return Color(red: 1.0, green: 0.0, blue: 1.0)
            }
        }
    
    var index: Int {
            Self.allCases.firstIndex(of: self)!
        }
}
