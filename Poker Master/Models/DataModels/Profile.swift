//
//  Profile.swift
//  Poker Master
//
//  Created by Ned Whittleton on 12/8/25.
//

import Foundation
import SwiftData

@Model
class Profile {
    @Attribute(.unique) var id: UUID
    var username: String
    var email: String? = nil // Not required
    var avatar: String? = nil // image name or URL
    
    var xp: Int = 0 // starts at 0
    var totalXP: Int = 0
    
    var level: Int = 1 // starts at 1
    var leveledUP: Bool = false
    
    var xpNeededForNextLevel: Int {
        Int(10 * log(Double(level) + 1)) // log curve
    }
    
    init(username: String) {
        self.id = UUID()
        self.username = username
    }
    
    func addXP(amount: Int) {
        xp += amount
        totalXP += amount
        while xp >= xpNeededForNextLevel {
            xp -= xpNeededForNextLevel
            level += 1
            leveledUP = true
        }
    }
}
