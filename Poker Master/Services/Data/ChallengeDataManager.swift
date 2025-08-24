//
//  ChallengeDataManager.swift
//  Poker Master
//
//  Created by Ned Whittleton on 8/23/25.
//

import Foundation
import SwiftData

struct ChallengeDataManager {
    
    @MainActor
    static func preloadChallengesIfNeeded(context: ModelContext) async {
        // 1️⃣ Create a FetchDescriptor
        let fetchDescriptor = FetchDescriptor<Challenges>(predicate: nil)

        // 2️⃣ Fetch all Challenges
        let existingChallenges = try? context.fetch(fetchDescriptor)

        // 3️⃣ If already exist, do nothing
        if let existing = existingChallenges, !existing.isEmpty { return }

        // 4️⃣ Otherwise, insert defaults
        let defaultChallenges: [(title: String, desc: String, icon: String, goals: [Int])] = [
            ("Volume Player", "Play hands", "suit.club.fill", [10, 50, 200, 500, 1500, 3000]),
            ("Poker IQ", "Make right plays", "brain.fill", [5, 25, 100, 250, 750, 1500]),
            ("Pocket Rockets", "Hit pocket pairs", "die.face.2.fill", [5, 20, 100, 300, 800, 1500]),
            ("Hot Hand", "Correct 3 times in a row", "flame.fill", [5, 20, 100, 300, 800, 1500]),
            ("Closer", "Finish full matches", "target", [5, 20, 100, 300, 800, 1500]),
            ("Perfect Game", "Games without errors", "target", [5, 20, 100, 300, 800, 1500])
        ]

        for data in defaultChallenges {
            let challenge = Challenges(
                title: data.title,
                description: data.desc,
                icon: data.icon,
                goals: data.goals
            )
            context.insert(challenge)
        }

        try? context.save()
    }
    
    // Function to add new challenge if it doesn't exist
    


}
